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

    func loadSnapshot() async throws -> FirebaseWorkoutSnapshot {
        guard let userID else { throw FirebaseSyncError.notConnected }

        let userReference = database.collection("users").document(userID)
        let userDocument = try await userReference.getDocument()
        let dailyState = userDocument.data().flatMap(Self.dailyState(from:))
        let recordsDocument = try await userReference.collection("workoutRecords").getDocuments()
        let records = recordsDocument.documents.compactMap(Self.record(from:))

        return FirebaseWorkoutSnapshot(dailyState: dailyState, records: records)
    }

    func deleteAccount() async throws {
        guard let userID else { return }

        let userReference = database.collection("users").document(userID)
        for collectionName in ["workoutRecords", "coachUsage"] {
            let documents = try await userReference.collection(collectionName).getDocuments()
            for document in documents.documents {
                try await document.reference.delete()
            }
        }
        try await userReference.delete()

        if let user = Auth.auth().currentUser {
            try await user.delete()
        }
        self.userID = nil
    }

    private func save(record: WorkoutRecord, under userReference: DocumentReference) async throws {
        try await userReference.collection("workoutRecords").document(record.id.uuidString).setData([
            "planID": record.planID,
            "sessionType": record.sessionType.rawValue,
            "completedAt": Timestamp(date: record.completedAt),
            "durationMinutes": record.durationMinutes
        ], merge: true)
    }

    private static func dailyState(from data: [String: Any]) -> DailyState? {
        guard let raw = data["dailyState"] as? [String: Any],
              let availableMinutes = raw["availableMinutes"] as? Int,
              let energyRaw = raw["energy"] as? String,
              let energy = EnergyLevel(rawValue: energyRaw),
              let bodyStatusRaw = raw["bodyStatus"] as? String,
              let bodyStatus = BodyStatus(rawValue: bodyStatusRaw),
              let interruptionRisk = raw["interruptionRisk"] as? Bool,
              let focusRaw = raw["focus"] as? String,
              let focus = FocusArea(rawValue: focusRaw)
        else {
            return nil
        }

        return DailyState(
            availableMinutes: availableMinutes,
            energy: energy,
            bodyStatus: bodyStatus,
            interruptionRisk: interruptionRisk,
            focus: focus
        )
    }

    private static func record(from document: QueryDocumentSnapshot) -> WorkoutRecord? {
        guard let id = UUID(uuidString: document.documentID),
              let data = document.data() as [String: Any]?,
              let planID = data["planID"] as? String,
              let sessionTypeRaw = data["sessionType"] as? String,
              let sessionType = SessionType(rawValue: sessionTypeRaw),
              let completedAt = (data["completedAt"] as? Timestamp)?.dateValue(),
              let durationMinutes = data["durationMinutes"] as? Int
        else {
            return nil
        }

        return WorkoutRecord(
            id: id,
            planID: planID,
            sessionType: sessionType,
            completedAt: completedAt,
            durationMinutes: durationMinutes
        )
    }
}

enum FirebaseSyncError: Error {
    case notConfigured
    case notConnected
}

struct FirebaseWorkoutSnapshot {
    let dailyState: DailyState?
    let records: [WorkoutRecord]
}
