import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @State private var reminderRequestInProgress = false

    var body: some View {
        Form {
            Section {
                Toggle("20:50に2分のきっかけを通知", isOn: Binding(
                    get: { store.reminderEnabled },
                    set: { enabled in
                        if enabled {
                            reminderRequestInProgress = true
                            Task {
                                _ = await store.requestReminderPermission()
                                await MainActor.run {
                                    reminderRequestInProgress = false
                                }
                            }
                        } else {
                            store.disableReminder()
                        }
                    }
                ))
                .disabled(reminderRequestInProgress)
            } header: {
                Text("通知")
            } footer: {
                Text("忘れていても思い出せるように、1日1回だけ届きます。")
            }

            Section {
                Label(store.syncStatus.title, systemImage: store.syncStatus == .connected ? "checkmark.icloud" : "icloud")
                    .foregroundStyle(store.syncStatus == .connected ? AppColor.positive : .secondary)
            } header: {
                Text("データ")
            } footer: {
                Text("トレーニング記録と今日の状態だけを匿名で同期します。写真は送信しません。")
            }

            Section {
                Text("LINE Seed JP")
                Text("LINE Seed JPをSIL Open Font License 1.1に従って使用しています。")
                    .font(AppFont.regular(13, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            } header: {
                Text("フォント")
            }

            Section {
                Text("写真や生成画像は端末内に保存します。Firebaseには匿名アカウント、今日の状態、トレーニング完了記録だけを保存します。")
                    .font(AppFont.regular(14, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
            } header: {
                Text("プライバシー")
            }
        }
        .font(AppFont.regular(16, relativeTo: .body))
        .navigationTitle("設定")
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
