import SwiftUI

struct DailyStateSheet: View {
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: DailyState

    init() {
        _draft = State(initialValue: DailyState())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("今日の狙い", selection: $draft.focus) {
                        ForEach(FocusArea.allCases) { focus in
                            Text(focus.title).tag(focus)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("今日は、どこを変えたい？")
                } footer: {
                    Text(draft.focus.detail)
                }

                Section {
                    Picker("使えそうな時間", selection: $draft.availableMinutes) {
                        Text("まずは2分").tag(2)
                        Text("10分くらい").tag(10)
                        Text("15分以上").tag(15)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("いま使えそうな時間")
                } footer: {
                    Text("迷ったら2分を選べば大丈夫です。")
                }

                Section {
                    Picker("いまの体力", selection: $draft.energy) {
                        ForEach(EnergyLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }

                    Picker("身体の状態", selection: $draft.bodyStatus) {
                        ForEach(BodyStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }
                } header: {
                    Text("いまのコンディション")
                } footer: {
                    Text("痛みがある日は休みます。違和感が出たら途中でやめ、無理のない種目へ替えてください。")
                }

                Section {
                    Toggle("途中で呼ばれるかもしれない", isOn: $draft.interruptionRisk)
                } header: {
                    Text("今日の生活")
                } footer: {
                    Text("オンなら、短く終わるメニューを優先します。中断しても、戻ってこられれば成功です。")
                }
            }
            .font(AppFont.regular(16, relativeTo: .body))
            .navigationTitle("今日の状態")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.updateDailyState(draft)
                        dismiss()
                    }
                    .font(AppFont.bold(16, relativeTo: .body))
                }
            }
            .onAppear {
                draft = store.dailyState
            }
        }
    }
}
