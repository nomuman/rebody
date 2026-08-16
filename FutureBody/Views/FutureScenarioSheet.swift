import SwiftUI

struct FutureScenarioSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("魅力と能力を更新する")
                            .font(AppFont.extraBold(32, relativeTo: .largeTitle))
                        Text("見た目だけでも、体力だけでもない。自分の身体をもう一度好きになるために。")
                            .font(AppFont.regular(16, relativeTo: .body))
                            .foregroundStyle(.secondary)
                    }

                    scenario(title: "お腹まわりが整う未来", detail: "Tシャツ姿の自分を、今より好きになる", color: AppColor.accentSoft, icon: "tshirt")
                    scenario(title: "胸と腕に存在感が出る未来", detail: "細い腕・薄い胸を、少しずつ変えていく", color: Color(uiColor: .secondarySystemBackground), icon: "figure.strengthtraining.functional")
                    scenario(title: "動く・支える力が上がる未来", detail: "テニスや子どもの抱っこが、少し軽くなる", color: Color(uiColor: .tertiarySystemBackground), icon: "figure.run")
                    scenario(title: "再開できる自分が残る未来", detail: "忙しい日も、2分から戻ってこられる", color: AppColor.warm.opacity(0.35), icon: "arrow.uturn.forward")

                        Text("未来を決める必要はありません。今日は、変えたいところから一歩だけ選びます。")
                        .font(AppFont.regular(14, relativeTo: .subheadline))
                        .foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .navigationTitle("未来の選択肢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func scenario(title: String, detail: String, color: Color, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.bold(18, relativeTo: .headline))
                Text(detail)
                    .font(AppFont.regular(14, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
