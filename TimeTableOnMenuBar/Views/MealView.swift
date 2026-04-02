import SwiftUI
import Foundation

struct MealView: View {
    @EnvironmentObject var timetableStore: TimetableStore
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        if !settingsStore.hasNEISCodes {
            noSchoolState
        } else if timetableStore.todayMeals.isEmpty {
            emptyState
        } else {
            mealList
        }
    }

    private var noSchoolState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("급식 정보를 불러올 수 없습니다")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text("학교를 다시 설정해주세요")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .modifier(GlassCardModifier())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "fork.knife")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("오늘은 급식이 없어요")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .padding()
        .modifier(GlassCardModifier())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mealList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(timetableStore.todayMeals) { meal in
                    mealCard(meal)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private func mealCard(_ meal: MealEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: mealIcon(meal.mealType))
                    .foregroundStyle(.orange)
                Text(meal.mealType.label)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if let cal = meal.calorie {
                    Text(cal)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            ForEach(meal.items) { item in
                HStack(alignment: .top, spacing: 6) {
                    Text("·")
                        .foregroundStyle(.orange)
                    Text(item.cleanName)
                        .font(.system(size: 13))
                    Spacer()
                    if !item.allergens.isEmpty {
                        Text(item.allergens.map(String.init).joined(separator: "."))
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func mealIcon(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        }
    }
}
