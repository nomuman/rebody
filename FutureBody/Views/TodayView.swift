import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: WorkoutStore
    @State private var showingState = false
    @State private var showingFuture = false
    @State private var showingWorkout = false
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                durationChooser
                recommendationCard
                coachCard
                stateCard
                weeklyCard
                futureCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("今日")
        .task {
            await store.refreshCoachMessage()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("設定")
            }
        }
        .sheet(isPresented: $showingState) {
            DailyStateSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingFuture) {
            FutureScenarioSheet()
        }
        .sheet(isPresented: $showingWorkout) {
            WorkoutPlayerView(plan: store.recommendedPlan)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(store)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(AppFont.regular(15, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
            Text(store.completedToday ? "今日の一歩を完了" : "今日の一歩")
                .font(AppFont.extraBold(26, relativeTo: .title))
                .foregroundStyle(.primary)
            Text(store.completedToday ? "完璧よりも、戻ってこられることが変化をつくります。" : "魅力と能力は、今日の一回から")
                .font(AppFont.regular(15, relativeTo: .body))
                .foregroundStyle(.secondary)
        }
    }

    private var durationChooser: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading("今日は何分？", subtitle: "選んだ時間に合わせてメニューを組みます")

            HStack(spacing: 8) {
                durationOption(minutes: 2, title: "2分", subtitle: "まず一歩")
                durationOption(minutes: 10, title: "10分", subtitle: "土台づくり")
                durationOption(minutes: 15, title: "15分以上", subtitle: "しっかり")
            }

            if store.shouldRestToday {
                Label("痛みがあるため、今日は休む提案です", systemImage: "pause.circle")
                    .font(AppFont.regular(13, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            } else if store.dailyState.energy == .low && selectedDuration > 2 {
                Label("疲れが強い日は、身体に合わせて短く調整します", systemImage: "heart.text.square")
                    .font(AppFont.regular(13, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            }
        }
        .cardSurface()
    }

    private func durationOption(minutes: Int, title: String, subtitle: String) -> some View {
        let isSelected = selectedDuration == minutes

        return Button {
            chooseDuration(minutes)
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(AppFont.bold(18, relativeTo: .headline))
                Text(subtitle)
                    .font(AppFont.regular(11, relativeTo: .caption))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(isSelected ? AppColor.accent : Color(uiColor: .tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)のトレーニング")
        .accessibilityValue(isSelected ? "選択中" : "未選択")
    }

    private var futureCard: some View {
        Button {
            showingFuture = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppColor.warm)
                        .frame(width: 72, height: 72)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("魅力と能力を更新する")
                        .font(AppFont.bold(18, relativeTo: .headline))
                    Text("お腹・胸・腕・動ける力は、今日の一回から")
                        .font(AppFont.regular(14, relativeTo: .subheadline))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardSurface()
        .accessibilityHint("未来の自分のイメージを表示します")
    }

    private var stateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading("今日の狙いと条件", subtitle: stateSummary)

            Button("目的・体調を変える") {
                showingState = true
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .cardSurface()
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(store.coachSource == .onDevice ? "iPhone内のAIコーチ" : "今日のコーチ", systemImage: "sparkles")
                    .font(AppFont.bold(16, relativeTo: .headline))
                Spacer()
                Button {
                    Task {
                        await store.refreshCoachMessage(force: true)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("コーチのひとことを更新")
            }

            Text(store.coachMessage)
                .font(AppFont.regular(15, relativeTo: .body))
                .foregroundStyle(.primary)

            Text(store.coachSource == .onDevice ? "このiPhone内で、今日の状態と最近の一歩をもとにしています" : "今日の状態から、すぐできる一歩を提案しています")
                .font(AppFont.regular(12, relativeTo: .caption))
                .foregroundStyle(.secondary)
        }
        .cardSurface()
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if store.shouldRestToday {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(AppColor.accent)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("今日は休む日")
                            .font(AppFont.bold(20, relativeTo: .title3))
                        Text("痛みがある日は、筋トレをしなくて大丈夫です。")
                            .font(AppFont.regular(14, relativeTo: .subheadline))
                            .foregroundStyle(.secondary)
                    }
                }

                Button("目的・体調を変える") {
                    showingState = true
                }
                .buttonStyle(SecondaryButtonStyle())

                Text("痛みが続く、または強くなる場合は運動をせず、専門家に相談してください。")
                    .font(AppFont.regular(13, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("今日のアップデート")
                            .font(AppFont.regular(14, relativeTo: .subheadline))
                            .foregroundStyle(.secondary)
                        Text(store.recommendedPlan.title)
                            .font(AppFont.bold(20, relativeTo: .title3))
                        Text("\(store.recommendedPlan.type.durationLabel) · \(store.recommendedPlan.format)")
                            .font(AppFont.bold(14, relativeTo: .subheadline))
                            .foregroundStyle(AppColor.accent)
                        Text(store.recommendedPlan.subtitle)
                            .font(AppFont.regular(14, relativeTo: .subheadline))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(store.recommendedPlan.type.durationLabel)
                        .font(AppFont.extraBold(24, relativeTo: .title2))
                        .foregroundStyle(AppColor.accent)
                }

                Button {
                    showingWorkout = true
                } label: {
                    Label("\(store.recommendedPlan.type.durationLabel)を始める", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .cardSurface()
    }

    private var weeklyCard: some View {
        HStack(spacing: 16) {
            ProgressRing(progress: min(Double(store.completedThisWeek) / 3, 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(store.completedToday ? "今日の一歩を記録しました" : "今週の一歩")
                    .font(AppFont.bold(17, relativeTo: .headline))
                Text("\(store.completedThisWeek) / 3回")
                    .font(AppFont.extraBold(25, relativeTo: .title2))
                    Text("週3回を目安に、更新できた日を数えます")
                    .font(AppFont.regular(13, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            }
        }
        .cardSurface()
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "おはようございます"
        case 12..<18:
            return "午後も無理なく"
        default:
            return "今日もおつかれさまです"
        }
    }

    private var stateSummary: String {
        "\(store.dailyState.focus.title) · \(availableTimeLabel) · \(store.dailyState.energy.title) · \(store.dailyState.bodyStatus.title)"
    }

    private var availableTimeLabel: String {
        switch store.dailyState.availableMinutes {
        case ...2:
            return "2分"
        case 3..<15:
            return "10分"
        default:
            return "15分以上"
        }
    }

    private var selectedDuration: Int {
        switch store.dailyState.availableMinutes {
        case ...2:
            return 2
        case 3..<15:
            return 10
        default:
            return 15
        }
    }

    private func chooseDuration(_ minutes: Int) {
        var state = store.dailyState
        state.availableMinutes = minutes
        store.updateDailyState(state)
        Task {
            await store.refreshCoachMessage(force: true)
        }
    }
}

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.accentSoft, lineWidth: 9)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppColor.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "figure.strengthtraining.traditional")
                .foregroundStyle(AppColor.accent)
        }
        .frame(width: 66, height: 66)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("今週のトレーニング進捗")
        .accessibilityValue("\(Int(progress * 100))パーセント")
    }
}
