import SwiftUI

struct ProgressViewScreen: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var showingFuture = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading("記録", subtitle: "魅力と能力を更新できた回数を見ます")

                VStack(spacing: 16) {
                    metric(title: "今週できたこと", value: "\(store.completedThisWeek)回", detail: "週3回を目安に")
                    metric(title: "これまでの一歩", value: "\(store.totalCompleted)回", detail: "2分の日も含みます")
                    metric(title: "次にできること", value: nextActionValue, detail: store.completedToday ? "今日はもう十分" : "迷ったらここから")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("魅力と能力")
                        .font(AppFont.bold(20, relativeTo: .title3))
                    Text("見た目の変化には時間がかかります。まずは、お腹・胸・腕・動ける力を更新できた日を記録します。")
                        .font(AppFont.regular(15, relativeTo: .body))
                        .foregroundStyle(.secondary)
                    Button("更新したい未来を見る") {
                        showingFuture = true
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .cardSurface()
            }
            .padding(20)
        }
        .navigationTitle("変化")
        .sheet(isPresented: $showingFuture) {
            FutureScenarioSheet()
        }
    }

    private var nextActionValue: String {
        if store.shouldRestToday {
            return "休む"
        }

        if store.completedToday {
            return "できた"
        }

        return "\(store.recommendedPlan.type.minutes)分"
    }

    private func metric(title: String, value: String, detail: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.regular(14, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(AppFont.extraBold(30, relativeTo: .title))
                    .foregroundStyle(AppColor.accent)
            }
            Spacer()
            Text(detail)
                .font(AppFont.regular(14, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
        }
        .cardSurface()
    }
}
