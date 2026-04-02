import Foundation

nonisolated final class NEISService: Sendable {

    // MARK: - Constants

    private static let baseURL = "https://open.neis.go.kr/hub"

    // MARK: - NEIS School Search

    struct NEISSchool: Sendable {
        let officeCode: String   // ATPT_OFCDC_SC_CODE
        let schoolCode: String   // SD_SCHUL_CODE
        let name: String
        let address: String
    }

    func searchSchool(name: String) async throws -> [NEISSchool] {
        var components = URLComponents(string: "\(Self.baseURL)/schoolInfo")!
        components.queryItems = [
            URLQueryItem(name: "Type", value: "json"),
            URLQueryItem(name: "pIndex", value: "1"),
            URLQueryItem(name: "pSize", value: "20"),
            URLQueryItem(name: "SCHUL_NM", value: name),
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let info = json["schoolInfo"] as? [[String: Any]],
              info.count >= 2,
              let rows = info[1]["row"] as? [[String: Any]] else {
            return []
        }

        return rows.compactMap { row in
            guard let officeCode = row["ATPT_OFCDC_SC_CODE"] as? String,
                  let schoolCode = row["SD_SCHUL_CODE"] as? String,
                  let name = row["SCHUL_NM"] as? String else {
                return nil
            }
            let address = row["ORG_RDNMA"] as? String ?? ""
            return NEISSchool(officeCode: officeCode, schoolCode: schoolCode, name: name, address: address)
        }
    }

    // MARK: - Meal Fetch

    func fetchMeals(
        officeCode: String,
        schoolCode: String,
        date: String,
        mealType: MealType? = nil
    ) async throws -> [MealEntry] {
        var components = URLComponents(string: "\(Self.baseURL)/mealServiceDietInfo")!
        var queryItems = [
            URLQueryItem(name: "Type", value: "json"),
            URLQueryItem(name: "ATPT_OFCDC_SC_CODE", value: officeCode),
            URLQueryItem(name: "SD_SCHUL_CODE", value: schoolCode),
            URLQueryItem(name: "MLSV_YMD", value: date),
        ]
        if let mealType {
            queryItems.append(URLQueryItem(name: "MMEAL_SC_CODE", value: String(mealType.rawValue)))
        }
        components.queryItems = queryItems

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let info = json["mealServiceDietInfo"] as? [[String: Any]],
              info.count >= 2,
              let rows = info[1]["row"] as? [[String: Any]] else {
            return []
        }

        return rows.compactMap { row -> MealEntry? in
            guard let dishNM = row["DDISH_NM"] as? String,
                  let mealCode = row["MMEAL_SC_CODE"] as? String,
                  let mealDate = row["MLSV_YMD"] as? String,
                  let mealTypeInt = Int(mealCode),
                  let type = MealType(rawValue: mealTypeInt) else {
                return nil
            }

            let items = parseDishItems(dishNM)
            let calorie = row["CAL_INFO"] as? String
            let origin = row["ORPLC_INFO"] as? String

            return MealEntry(
                date: mealDate,
                mealType: type,
                items: items,
                calorie: calorie,
                origin: origin
            )
        }
    }

    // MARK: - Weekly Meals

    func fetchWeeklyMeals(
        officeCode: String,
        schoolCode: String,
        baseDate: Date
    ) async throws -> [MealEntry] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: baseDate)
        // Monday = weekday 2
        let mondayOffset = 2 - weekday
        guard let monday = calendar.date(byAdding: .day, value: mondayOffset, to: baseDate),
              let friday = calendar.date(byAdding: .day, value: 4, to: monday) else {
            return []
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"

        var components = URLComponents(string: "\(Self.baseURL)/mealServiceDietInfo")!
        components.queryItems = [
            URLQueryItem(name: "Type", value: "json"),
            URLQueryItem(name: "ATPT_OFCDC_SC_CODE", value: officeCode),
            URLQueryItem(name: "SD_SCHUL_CODE", value: schoolCode),
            URLQueryItem(name: "MLSV_FROM_YMD", value: formatter.string(from: monday)),
            URLQueryItem(name: "MLSV_TO_YMD", value: formatter.string(from: friday)),
            URLQueryItem(name: "MMEAL_SC_CODE", value: "2"), // lunch only for weekly
        ]

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let info = json["mealServiceDietInfo"] as? [[String: Any]],
              info.count >= 2,
              let rows = info[1]["row"] as? [[String: Any]] else {
            return []
        }

        return rows.compactMap { row -> MealEntry? in
            guard let dishNM = row["DDISH_NM"] as? String,
                  let mealCode = row["MMEAL_SC_CODE"] as? String,
                  let mealDate = row["MLSV_YMD"] as? String,
                  let mealTypeInt = Int(mealCode),
                  let type = MealType(rawValue: mealTypeInt) else {
                return nil
            }

            let items = parseDishItems(dishNM)
            let calorie = row["CAL_INFO"] as? String
            let origin = row["ORPLC_INFO"] as? String

            return MealEntry(
                date: mealDate,
                mealType: type,
                items: items,
                calorie: calorie,
                origin: origin
            )
        }
    }

    // MARK: - Parsing

    private func parseDishItems(_ raw: String) -> [MealItem] {
        raw.components(separatedBy: "<br/>")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { parseSingleItem($0) }
    }

    private static let allergenRegex = try! NSRegularExpression(pattern: #"(\d+\.)+\s*$"#)

    private func parseSingleItem(_ raw: String) -> MealItem {
        // Pattern: "메뉴이름 1.2.5.6." or "메뉴이름(친환경)1.5.6."
        let nsRange = NSRange(raw.startIndex..., in: raw)
        if let match = Self.allergenRegex.firstMatch(in: raw, range: nsRange),
           let range = Range(match.range, in: raw) {
            let allergenStr = String(raw[range])
            let name = String(raw[raw.startIndex..<range.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let allergens = allergenStr
                .components(separatedBy: ".")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            return MealItem(name: name, allergens: allergens)
        }
        return MealItem(name: raw, allergens: [])
    }
}
