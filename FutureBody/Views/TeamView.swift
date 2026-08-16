import SwiftUI

struct TeamView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading("仲間", subtitle: "ひとりで始めて、あとで一緒に続けます")

                VStack(spacing: 16) {
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(AppColor.accent)
                        .frame(width: 84, height: 84)
                        .background(AppColor.accentSoft)
                        .clipShape(Circle())

                    VStack(spacing: 6) {
                        Text("まだ仲間はいません")
                            .font(AppFont.bold(20, relativeTo: .title3))
                        Text("家族や友だちと、できたかどうかだけを共有する機能を準備しています。")
                            .font(AppFont.regular(15, relativeTo: .body))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .cardSurface()

                VStack(alignment: .leading, spacing: 12) {
                    Label("共有するのは実行したことだけ", systemImage: "checkmark.circle")
                        .font(AppFont.bold(16, relativeTo: .body))
                    Label("体重や写真は共有しません", systemImage: "lock.shield")
                        .font(AppFont.regular(15, relativeTo: .body))
                        .foregroundStyle(.secondary)
                    Label("応援し合って、競争しすぎません", systemImage: "heart")
                        .font(AppFont.regular(15, relativeTo: .body))
                        .foregroundStyle(.secondary)
                }
                .cardSurface()

                Label("仲間機能は準備中です", systemImage: "clock")
                    .font(AppFont.regular(13, relativeTo: .caption))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(20)
        }
        .navigationTitle("仲間")
    }
}
