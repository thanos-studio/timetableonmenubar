import SwiftUI
import Foundation

struct GradeClassView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Binding var path: [OnboardingStep]

    @State private var grade: Int = 1
    @State private var classNum: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("학년/반 선택")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 24)
                .padding(.bottom, 8)

            Text("시간표를 가져올 학년과 반을 선택하세요")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)

            // Grade picker
            VStack(alignment: .leading, spacing: 8) {
                Text("학년")
                    .font(.headline)
                Picker("학년", selection: $grade) {
                    Text("1학년").tag(1)
                    Text("2학년").tag(2)
                    Text("3학년").tag(3)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            // Class stepper
            VStack(alignment: .leading, spacing: 8) {
                Text("반")
                    .font(.headline)
                HStack {
                    Text("\(classNum)반")
                        .font(.title3)
                        .monospacedDigit()
                        .frame(minWidth: 60, alignment: .leading)
                    Spacer()
                    Stepper("", value: $classNum, in: 1...20)
                        .labelsHidden()
                }
                .padding(12)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(.horizontal, 24)

            Spacer()

            // Summary
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("\(settingsStore.schoolName) \(grade)학년 \(classNum)반")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            Divider()

            // Next button
            HStack {
                Button("이전") {
                    path.removeLast()
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("다음") {
                    settingsStore.grade = grade
                    settingsStore.classNum = classNum
                    path.append(.periodConfig)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .onAppear {
            grade = settingsStore.grade
            classNum = settingsStore.classNum
        }
        .navigationBarBackButtonHidden(true)
    }
}
