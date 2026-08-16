import Foundation
import FirebaseCore
import UserNotifications

@MainActor
final class WorkoutStore: ObservableObject {
    @Published var dailyState = DailyState()
    @Published private(set) var records: [WorkoutRecord] = []
    @Published var reminderEnabled = false
    @Published private(set) var syncStatus: FirebaseSyncStatus = .localOnly

    private let persistenceKey = "futurebody.local-state"
    private let userDefaults: UserDefaults
    private var firebaseSync: FirebaseWorkoutSync?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
        Task {
            await connectToFirebase()
        }
    }

    var recommendedPlan: WorkoutPlan {
        if dailyState.availableMinutes <= 2 || dailyState.energy == .low || dailyState.bodyStatus == .pain || dailyState.interruptionRisk {
            return WorkoutCatalog.plan(for: dailyState.focus, type: .rescue)
        }

        if dailyState.availableMinutes >= 15 && dailyState.energy == .high && dailyState.bodyStatus == .good {
            return WorkoutCatalog.plan(for: dailyState.focus, type: .extended)
        }

        return WorkoutCatalog.plan(for: dailyState.focus, type: .standard)
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
        if let firebaseSync {
            try await firebaseSync.deleteAccount()
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["futurebody-evening-reminder"])
        userDefaults.removeObject(forKey: persistenceKey)
        dailyState = DailyState()
        records = []
        reminderEnabled = false
        firebaseSync = nil
        syncStatus = .localOnly
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
}

private struct PersistedState: Codable {
    let dailyState: DailyState
    let records: [WorkoutRecord]
    let reminderEnabled: Bool
}
