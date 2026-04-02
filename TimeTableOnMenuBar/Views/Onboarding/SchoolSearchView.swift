import SwiftUI
import Foundation

struct SchoolSearchView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Binding var path: [OnboardingStep]

    @State private var searchText = ""
    @State private var searchResults: [School] = []
    @State private var selectedSchool: School? = nil
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var searchTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("학교 검색")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 24)
                .padding(.bottom, 16)

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                NativeTextField(text: $searchText, placeholder: "학교 이름")
                if isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        selectedSchool = nil
                        errorMessage = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 24)

            // Results
            Group {
                if let errorMessage {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title3)
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Image(systemName: "building.2")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("검색 결과가 없습니다")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "building.columns")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("학교 이름을 입력하세요")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults, id: \.code) { school in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(school.name)
                                    .fontWeight(.medium)
                                Text(school.region)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedSchool?.code == school.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSchool = school
                            settingsStore.schoolCode = school.code
                            settingsStore.schoolName = school.name
                            lookupNEISCodes(for: school.name)
                        }
                        .listRowBackground(
                            selectedSchool?.code == school.code
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.top, 12)

            Divider()

            // Next button
            HStack {
                Spacer()
                Button("다음") {
                    path.append(.gradeClass)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedSchool == nil)
                .padding(16)
            }
        }
        .onChange(of: searchText) { newValue in
            searchTask?.cancel()
            errorMessage = nil

            guard !newValue.trimmingCharacters(in: .whitespaces).isEmpty else {
                searchResults = []
                selectedSchool = nil
                isSearching = false
                return
            }

            isSearching = true
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }

                do {
                    let results = try await ComciganService().searchSchool(keyword: newValue)
                    guard !Task.isCancelled else { return }
                    searchResults = results
                    errorMessage = nil
                } catch {
                    guard !Task.isCancelled else { return }
                    searchResults = []
                    errorMessage = "학교 검색에 실패했습니다. 인터넷 연결을 확인해주세요."
                }
                isSearching = false
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private func lookupNEISCodes(for schoolName: String) {
        Task {
            do {
                let results = try await NEISService().searchSchool(name: schoolName)
                if let match = results.first(where: { $0.name == schoolName }) ?? results.first {
                    settingsStore.neisOfficeCode = match.officeCode
                    settingsStore.neisSchoolCode = match.schoolCode
                }
            } catch {
                // NEIS lookup failure is non-blocking; meal feature just won't work
            }
        }
    }
}
