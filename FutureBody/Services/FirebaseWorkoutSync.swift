import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import Foundation

enum FirebaseSyncStatus: Equatable {
    case connecting
    case connected
    case localOnly

    var title: String {
        switch self {
        case .connecting:
            return "Firebaseに接続中"
        case .connected:
            return "Firebaseに同期中"
        case .localOnly:
            return "端末内に保存"
        }
    }
}

final class FirebaseWorkoutSync {
    private lazy var database = Firestore.firestore()
    private var userID: String?

    func connect() async throws {
        guard FirebaseApp.app() != nil else {
            throw FirebaseSyncError.notConfigured
        }

        if let currentUser = Auth.auth().currentUser {
            userID = currentUser.uid
            return
        }

        let result = try await Auth.auth().signInAnonymously()
        userID = result.user.uid
    }

    func save(state: DailyState, records: [WorkoutRecord]) async throws {
        guard let userID else { return }

        let userReference = database.collection("users").document(userID)
        try await userReference.setData([
            "lastSeenAt": Timestamp(date: Date()),
            "dailyState": [
                "availableMinutes": state.availableMinutes,
                "energy": state.energy.rawValue,
                "bodyStatus": state.bodyStatus.rawValue,
                "interruptionRisk": state.interruptionRisk,
                "focus": state.focus.rawValue
            ]
        ], merge: true)

        for record in records {
            try await save(record: record, under: userReference)
        }
    }

    func save(record: WorkoutRecord) async throws {
        guard let userID else { return }
        let userReference = database.collection("users").document(userID)
        try await save(record: record, under: userReference)
    }

    private func save(record: WorkoutRecord, under userReference: DocumentReference) async throws {
        try await userReference.collection("workoutRecords").document(record.id.uuidString).setData([
            "planID": record.planID,
            "sessionType": record.sessionType.rawValue,
            "completedAt": Timestamp(date: record.completedAt),
            "durationMinutes": record.durationMinutes
        ], merge: true)
    }
}

enum FirebaseSyncError: Error {
    case notConfigured
}
