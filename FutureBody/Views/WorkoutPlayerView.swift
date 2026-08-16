import SwiftUI

struct WorkoutPlayerView: View {
    let plan: WorkoutPlan
    @EnvironmentObject private var store: WorkoutStore
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var completed = false
    @State private var showingExitConfirmation = false

    private var currentExercise: Exercise {
        plan.exercises[currentIndex]
    }

    var body: some View {
        NavigationStack {
            Group {
                if completed {
                    completionView
                } else {
                    exerciseView
                }
            }
            .navigationTitle(plan.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !completed {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("中断") {
                            showingExitConfirmation = true
                        }
                    }
                }
            }
            .alert("トレーニングを中断しますか？", isPresented: $showingExitConfirmation) {
                Button("続ける", role: .cancel) {}
                Button("中断する", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("ここまでの内容は記録されません。")
            }
        }
    }

    private var exerciseView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                progressHeader

                VStack(spacing: 14) {
                    Image(systemName: currentExercise.systemImage)
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(AppColor.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 128)
                        .background(AppColor.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentExercise.name)
                            .font(AppFont.extraBold(29, relativeTo: .largeTitle))
                        Text(currentExercise.detail)
                            .font(AppFont.regular(16, relativeTo: .body))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .cardSurface()

                HStack(spacing: 12) {
                    Label("効かせる場所", systemImage: "scope")
                        .font(AppFont.regular(14, relativeTo: .subheadline))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(currentExercise.purpose)
                        .font(AppFont.bold(17, relativeTo: .headline))
                        .foregroundStyle(AppColor.accent)
                }
                .cardSurface()

                VStack(alignment: .leading, spacing: 14) {
                    Text("やり方")
                        .font(AppFont.bold(20, relativeTo: .title3))

                    ForEach(Array(currentExercise.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(AppFont.bold(14, relativeTo: .subheadline))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(AppColor.accent)
                                .clipShape(Circle())

                            Text(step)
                                .font(AppFont.regular(15, relativeTo: .body))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider()

                    Label {
                        Text(currentExercise.keyPoint)
                            .font(AppFont.regular(14, relativeTo: .subheadline))
                    } icon: {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(AppColor.warm)
                    }
                }
                .cardSurface()

                HStack {
                    Text("今日の目標")
                        .font(AppFont.regular(15, relativeTo: .body))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(currentExercise.target)
                        .font(AppFont.extraBold(24, relativeTo: .title2))
                        .foregroundStyle(AppColor.accent)
                }
                .cardSurface()

                Button {
                    advance()
                } label: {
                    Text(currentIndex == plan.exercises.count - 1 ? "この種目を終えて完了" : "できた、次の種目へ")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("種目 (currentIndex + 1) / (plan.exercises.count)")
                    .font(AppFont.bold(14, relativeTo: .subheadline))
                Spacer()
                Text("違和感が出たら、やめて大丈夫")
                    .font(AppFont.regular(12, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(plan.exercises.count))
                .tint(AppColor.accent)
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 76))
                .foregroundStyle(AppColor.positive)

            VStack(spacing: 8) {
                Text("今日の身体を更新しました")
                    .font(AppFont.extraBold(27, relativeTo: .title))
                    .multilineTextAlignment(.center)
                Text("\(plan.type.minutes)分の行動が、魅力と能力の土台になります。")
                    .font(AppFont.regular(16, relativeTo: .body))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button("自由時間に戻る") {
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func advance() {
        if currentIndex == plan.exercises.count - 1 {
            store.complete(plan: plan)
            completed = true
        } else {
            currentIndex += 1
        }
    }
}
