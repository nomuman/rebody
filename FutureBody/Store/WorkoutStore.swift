import Foundation
import FirebaseCore
import UserNotifications

@MainActor
final class WorkoutStore: ObservableObject {
    @Published var dailyState = DailyState()
    @Published private(set) var records: [WorkoutRecord] = []
    @Published var reminderEnabled = false
    @Published private(set) var syncStatus: FirebaseSyncStatus = .localOnly
    @Published private(set) var coachMessage = "今日できる分だけ、未来の自分へ一歩渡しましょう。"
    @Published private(set) var coachSource: CoachMessageSource = .fallback

    private let persistenceKey = "futurebody.local-state"
    private let userDefaults: UserDefaults
    private var firebaseSync: FirebaseWorkoutSync?
    private var lastCoachRequestKey: String?
    private var stateChangedBeforeSync = false

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
        Task {
            await connectToFirebase()
        }
    }

    var recommendedPlan: WorkoutPlan {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let variation = (records.count + dayOfYear) % WorkoutCatalog.variationCount

        if dailyState.availableMinutes <= 2 || dailyState.bodyStatus == .pain || dailyState.energy == .low {
            return WorkoutCatalog.plan(for: dailyState.focus, type: .rescue, variation: variation)
        }

        if dailyState.availableMinutes >= 15 {
            return WorkoutCatalog.plan(for: dailyState.focus, type: .extended, variation: variation)
        }

        return WorkoutCatalog.plan(for: dailyState.focus, type: .standard, variation: variation)
    }

    var completedThisWeek: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDate($0.completedAt, equalTo: Date(), toGranularity: .weekOfYear) }.count
    }

    var totalCompleted: Int {
        records.count
    }

    var completedToday: Bool {
        records.contains { Calendar.current.isDateInToday($0.completedAt) }
    }

    var shouldRestToday: Bool {
        dailyState.bodyStatus == .pain
    }

    var lastCompletedDate: Date? {
        records.sorted { $0.completedAt > $1.completedAt }.first?.completedAt
    }

    func updateDailyState(_ state: DailyState) {
        dailyState = state
        stateChangedBeforeSync = true
        save()
        Task {
            await syncState()
        }
    }

    func complete(plan: WorkoutPlan) {
        let record = WorkoutRecord(
            id: UUID(),
            planID: plan.id,
            sessionType: plan.type,
            completedAt: Date(),
            durationMinutes: plan.type.minutes
        )
        records.append(record)
        save()
        Task {
            await syncRecord(record)
        }
    }

    func requestReminderPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            if granted {
                await scheduleReminder()
            }
            await MainActor.run {
                self.reminderEnabled = granted
                self.save()
            }
            return granted
        } catch {
            return false
        }
    }

    func disableReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["futurebody-evening-reminder"])
        reminderEnabled = false
        save()
    }

    func deleteAllData() async throws {
        if FirebaseApp.app() != nil {
            if firebaseSync == nil {
                await connectToFirebase()
            }

            guard let firebaseSync else {
                throw FirebaseSyncError.notConfigured
            }

            try await firebaseSync.deleteAccount()
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["futurebody-evening-reminder"])
        userDefaults.removeObject(forKey: persistenceKey)
        dailyState = DailyState()
        records = []
        reminderEnabled = false
        firebaseSync = nil
        syncStatus = .localOnly
        stateChangedBeforeSync = false
        coachMessage = "今日できる分だけ、未来の自分へ一歩渡しましょう。"
        coachSource = .fallback
        lastCoachRequestKey = nil
    }

    func refreshCoachMessage(force: Bool = false) async {
        let plan = recommendedPlan
        let requestKey = coachRequestKey(plan: plan)
        guard force || lastCoachRequestKey != requestKey else { return }
        lastCoachRequestKey = requestKey
        coachMessage = LocalCoachMessage.make(state: dailyState, plan: plan)
        coachSource = .fallback
        let result = await LocalCoachService.makeMessage(state: dailyState, plan: plan, records: records)
        coachMessage = result.message
        coachSource = result.source
    }

    private func scheduleReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "今夜の一手"
        content.body = "2分だけ、魅力と能力を更新します"
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 50
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "futurebody-evening-reminder", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func save() {
        let payload = PersistedState(dailyState: dailyState, records: records, reminderEnabled: reminderEnabled)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        userDefaults.set(data, forKey: persistenceKey)
    }

    private func load() {
        guard
            let data = userDefaults.data(forKey: persistenceKey),
            let payload = try? JSONDecoder().decode(PersistedState.self, from: data)
        else {
            return
        }

        dailyState = payload.dailyState
        records = payload.records
        reminderEnabled = payload.reminderEnabled
    }

    private func connectToFirebase() async {
        guard FirebaseApp.app() != nil else {
            syncStatus = .localOnly
            return
        }

        syncStatus = .connecting
        do {
            let sync = FirebaseWorkoutSync()
            try await sync.connect()
            firebaseSync = sync
            let snapshot = try await sync.loadSnapshot()
            if !stateChangedBeforeSync, let remoteState = snapshot.dailyState {
                dailyState = remoteState
            }
            mergeRecords(snapshot.records)
            save()
            try await sync.save(state: dailyState, records: records)
            syncStatus = .connected
        } catch {
            syncStatus = .localOnly
        }
    }

    private func syncState() async {
        if firebaseSync == nil {
            await connectToFirebase()
        }
        guard let firebaseSync else { return }
        do {
            try await firebaseSync.save(state: dailyState, records: records)
            syncStatus = .connected
        } catch {
            syncStatus = .localOnly
        }
    }

    private func syncRecord(_ record: WorkoutRecord) async {
        if firebaseSync == nil {
            await connectToFirebase()
        }
        guard let firebaseSync else { return }
        do {
            try await firebaseSync.save(record: record)
            syncStatus = .connected
        } catch {
            syncStatus = .localOnly
        }
    }

    private func coachRequestKey(plan: WorkoutPlan) -> String {
        let latestRecord = records.sorted { $0.completedAt > $1.completedAt }.first?.id.uuidString ?? "none"
        return [
            dailyState.focus.rawValue,
            dailyState.energy.rawValue,
            dailyState.bodyStatus.rawValue,
            String(dailyState.availableMinutes),
            String(dailyState.interruptionRisk),
            plan.id,
            latestRecord
        ].joined(separator: "|")
    }

    private func mergeRecords(_ remoteRecords: [WorkoutRecord]) {
        records = mergeWorkoutRecords(remoteRecords: remoteRecords, localRecords: records)
    }
}

func mergeWorkoutRecords(remoteRecords: [WorkoutRecord], localRecords: [WorkoutRecord]) -> [WorkoutRecord] {
    var merged = [UUID: WorkoutRecord](minimumCapacity: remoteRecords.count + localRecords.count)
    for record in remoteRecords {
        merged[record.id] = record
    }
    for record in localRecords {
        merged[record.id] = record
    }
    return merged.values.sorted { $0.completedAt < $1.completedAt }
}

private struct PersistedState: Codable {
    let dailyState: DailyState
    let records: [WorkoutRecord]
    let reminderEnabled: Bool
}
