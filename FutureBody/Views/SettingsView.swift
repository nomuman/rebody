import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @State private var reminderRequestInProgress = false
    @State private var showingDeleteConfirmation = false
    @State private var deletingData = false
    @State private var showingDeleteSuccess = false
    @State private var showingDeleteError = false

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
                Text("トレーニング記録と今日の状態だけを匿名で同期します。写真は送信しません。AIコーチの処理はこのiPhone内で行います。")
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
                Text("写真は収集しません。Firebaseには匿名アカウント、今日の状態、トレーニング完了記録を保存します。AIコーチの入力と生成結果は外部へ送信しません。")
                    .font(AppFont.regular(14, relativeTo: .subheadline))
                    .foregroundStyle(.secondary)
            } header: {
                Text("プライバシー")
            }

            Section {
                Link("プライバシーポリシー", destination: URL(string: "https://future-body-app-20260816.web.app/privacy")!)
                Link("サポート", destination: URL(string: "https://future-body-app-20260816.web.app/support")!)
            } header: {
                Text("ご案内")
            }

            Section {
                Button("アカウントとデータを削除", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                .disabled(deletingData)

                Text("匿名アカウント、同期した記録、端末内の記録を削除します。この操作は元に戻せません。")
                    .font(AppFont.regular(13, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            } header: {
                Text("アカウントとデータ")
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
        .confirmationDialog("アカウントとデータを削除しますか？", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("削除する", role: .destructive) {
                deleteData()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("匿名アカウント、同期データ、端末内の記録をすべて削除します。")
        }
        .alert("削除しました", isPresented: $showingDeleteSuccess) {
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("アカウントと記録を削除しました。")
        }
        .alert("削除できませんでした", isPresented: $showingDeleteError) {
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("通信を確認して、もう一度お試しください。端末内の記録はまだ削除されていません。")
        }
    }

    private func deleteData() {
        deletingData = true
        Task {
            do {
                try await store.deleteAllData()
                await MainActor.run {
                    deletingData = false
                    showingDeleteSuccess = true
                }
            } catch {
                await MainActor.run {
                    deletingData = false
                    showingDeleteError = true
                }
            }
        }
    }
}
