import Foundation

nonisolated final class ComciganService: Sendable {

    // MARK: - Constants

    private static let baseURL = "http://comci.net:4082"
    private static let userAgent =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36"
    private static let weekdays = ["월", "화", "수", "목", "금"]

    // MARK: - Regex patterns (NSRegularExpression for lookbehind support)

    private enum Patterns {
        static let mainRoute    = try! NSRegularExpression(pattern: #"(?<=\./)\d+(?=\?\d+l)"#)
        static let searchRoute  = try! NSRegularExpression(pattern: #"(?<=\?)\d+(?=l)"#)
        static let timetableRoute = try! NSRegularExpression(pattern: #"(?<=')\d+(?=_')"#)
        static let teacherCode  = try! NSRegularExpression(pattern: #"(?<=성명=자료\.자료)\d+"#)
        static let originalCode = try! NSRegularExpression(pattern: #"(?<=원자료=Q자료\(자료\.자료)\d+"#)
        static let dayCode      = try! NSRegularExpression(pattern: #"(?<=일일자료=Q자료\(자료\.자료)\d+"#)
        static let subjectCode  = try! NSRegularExpression(pattern: #"(?<=자료\.자료)\d+(?=\[sb\])"#)
        static let whiteSpace   = try! NSRegularExpression(pattern: #"\0+$"#)
    }

    // MARK: - Cache (actor-isolated for thread safety)

    private actor Cache {
        var routeData: RouteData?
        var cacheDate: Int = 0

        func get(today: Int) -> RouteData? {
            guard cacheDate == today else { return nil }
            return routeData
        }

        func set(_ data: RouteData, date: Int) {
            routeData = data
            cacheDate = date
        }
    }

    private let cache = Cache()

    // MARK: - EUC-KR Encoding

    private static let eucKREncoding = String.Encoding(
        rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)
        )
    )

    // MARK: - Network helpers

    private func fetchPage(url: String) async throws -> String {
        guard let requestURL = URL(string: url) else {
            throw ComciganError.invalidURL(url)
        }
        var request = URLRequest(url: requestURL)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let decoded = String(data: data, encoding: Self.eucKREncoding) else {
            throw ComciganError.decodingFailed
        }
        return decoded
    }

    private func fetchText(url: String) async throws -> String {
        guard let requestURL = URL(string: url) else {
            throw ComciganError.invalidURL(url)
        }
        var request = URLRequest(url: requestURL)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let text = String(data: data, encoding: .utf8) else {
            throw ComciganError.decodingFailed
        }
        return text
    }

    // MARK: - Parsing helpers

    private func extractMatch(_ regex: NSRegularExpression, in text: String, name: String) throws -> String {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text) else {
            throw ComciganError.extractionFailed(name)
        }
        return String(text[matchRange])
    }

    private func parseResponse(_ str: String) throws -> [String: Any] {
        let cleaned = Patterns.whiteSpace.stringByReplacingMatches(
            in: str,
            range: NSRange(str.startIndex..., in: str),
            withTemplate: ""
        )
        guard let data = cleaned.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ComciganError.jsonParseFailed
        }
        return json
    }

    // MARK: - Route data

    func getRouteData() async throws -> RouteData {
        let today = Calendar.current.component(.day, from: Date())
        if let cached = await cache.get(today: today) {
            return cached
        }
        let html = try await fetchPage(url: "\(Self.baseURL)/st")
        let routeData = RouteData(
            mainRoute: try extractMatch(Patterns.mainRoute, in: html, name: "mainRoute"),
            searchRoute: try extractMatch(Patterns.searchRoute, in: html, name: "searchRoute"),
            timetableRoute: try extractMatch(Patterns.timetableRoute, in: html, name: "timetableRoute"),
            teacherCode: try extractMatch(Patterns.teacherCode, in: html, name: "teacherCode"),
            originalCode: try extractMatch(Patterns.originalCode, in: html, name: "originalCode"),
            dayCode: try extractMatch(Patterns.dayCode, in: html, name: "dayCode"),
            subjectCode: try extractMatch(Patterns.subjectCode, in: html, name: "subjectCode")
        )
        await cache.set(routeData, date: today)
        return routeData
    }

    // MARK: - EUC-KR percent encoding

    private func encodeEUCKR(_ str: String) -> String {
        guard let data = (str as NSString).data(using: Self.eucKREncoding.rawValue) else {
            return str
        }
        return data.map { String(format: "%%%02X", $0) }.joined()
    }

    // MARK: - Public API

    func searchSchool(keyword: String) async throws -> [School] {
        let routes = try await getRouteData()
        let encoded = encodeEUCKR(keyword)
        let url = "\(Self.baseURL)/\(routes.mainRoute)?\(routes.searchRoute)l\(encoded)"
        let text = try await fetchText(url: url)
        let data = try parseResponse(text)
        guard let results = data["학교검색"] as? [[Any]] else {
            return []
        }
        return results.compactMap { item -> School? in
            guard item.count >= 4,
                  let region = item[1] as? String,
                  let name = item[2] as? String,
                  let code = item[3] as? Int else {
                return nil
            }
            return School(code: code, name: name, region: region)
        }
    }

    func getTimetable(schoolCode: Int, grade: Int? = nil, classNum: Int? = nil) async throws -> [ClassTimetable] {
        let routes = try await getRouteData()
        let raw = "\(routes.timetableRoute)_\(schoolCode)_0_1"
        let encoded = Data(raw.utf8).base64EncodedString()
        let url = "\(Self.baseURL)/\(routes.mainRoute)_T?\(encoded)"
        let text = try await fetchText(url: url)
        guard text.count >= 18 else {
            throw ComciganError.timetableNotFound
        }
        let data = try parseResponse(text)

        let teachers = data["자료\(routes.teacherCode)"] as? [String] ?? []
        let subjects = data["자료\(routes.subjectCode)"] as? [String] ?? []
        let classCount = data["학급수"] as? [Int] ?? []
        let now = data["자료\(routes.dayCode)"] as? [[[[Int]]]] ?? []
        let original = data["자료\(routes.originalCode)"] as? [[[[Int]]]] ?? []

        let teachersLen = teachers.count > 1
            ? Int(floor(log10(Double(teachers.count - 1)))) + 1
            : 1

        let divisor = Int(pow(10.0, Double(teachersLen + 1)))
        let modulus = Int(pow(10.0, Double(teachersLen)))

        func getSubject(_ code: Int) -> String {
            guard code != 0 else { return "" }
            let idx = code / divisor
            return idx < subjects.count ? subjects[idx] : ""
        }

        func getTeacher(_ code: Int) -> String {
            guard code != 0 else { return "" }
            let idx = code % modulus
            return idx < teachers.count ? teachers[idx] : ""
        }

        var results: [ClassTimetable] = []
        let gradeStart = grade ?? 1
        let gradeEnd = grade ?? 3

        for g in gradeStart...gradeEnd {
            guard g < now.count else { continue }
            let maxClass = g < classCount.count ? classCount[g] : 0
            let classStart = classNum ?? 1
            let classEnd = classNum ?? maxClass

            for c in classStart...classEnd {
                guard c < now[g].count else { continue }
                var days: [String: [TimetableEntry]] = [:]

                for d in 1...5 {
                    guard d < now[g][c].count else { continue }
                    var dayEntries: [TimetableEntry] = []

                    for p in 1..<now[g][c][d].count {
                        let nowCode = now[g][c][d][p]
                        let origCode: Int
                        if g < original.count,
                           c < original[g].count,
                           d < original[g][c].count,
                           p < original[g][c][d].count {
                            origCode = original[g][c][d][p]
                        } else {
                            origCode = 0
                        }

                        guard nowCode != 0 else { continue }
                        let changed = nowCode != origCode

                        let entry: TimetableEntry
                        if changed && origCode > 0 {
                            entry = TimetableEntry(
                                subject: getSubject(nowCode),
                                teacher: getTeacher(nowCode),
                                changed: true,
                                originalSubject: getSubject(origCode),
                                originalTeacher: getTeacher(origCode)
                            )
                        } else {
                            entry = TimetableEntry(
                                subject: getSubject(nowCode),
                                teacher: getTeacher(nowCode),
                                changed: changed,
                                originalSubject: nil,
                                originalTeacher: nil
                            )
                        }
                        dayEntries.append(entry)
                    }

                    let weekday = Self.weekdays[d - 1]
                    days[weekday] = dayEntries
                }

                results.append(ClassTimetable(grade: g, classNumber: c, days: days))
            }
        }

        return results
    }
}

// MARK: - Errors

enum ComciganError: LocalizedError {
    case invalidURL(String)
    case decodingFailed
    case extractionFailed(String)
    case jsonParseFailed
    case timetableNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .decodingFailed:
            return "Failed to decode response"
        case .extractionFailed(let name):
            return "Failed to extract \(name) from comcigan page"
        case .jsonParseFailed:
            return "Failed to parse JSON response"
        case .timetableNotFound:
            return "시간표 데이터를 찾을 수 없습니다."
        }
    }
}
