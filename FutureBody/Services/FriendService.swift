import CryptoKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseFunctions
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

extension Notification.Name {
    static let futureBodyFCMTokenUpdated = Notification.Name("futureBodyFCMTokenUpdated")
}

struct FriendProfile: Identifiable, Hashable {
    let id: String
    let displayName: String
    let currentStreakDays: Int
    let totalWorkoutDays: Int
    let weeklyWorkoutDays: Int
    let lastWorkoutDate: String?

    var lastWorkoutLabel: String {
        guard let lastWorkoutDate else { return "まだ記録がありません" }
        if lastWorkoutDate == Self.dateKey(for: Date()) {
            return "今日の一歩を完了"
        }
        if lastWorkoutDate == Self.dateKey(for: Date(timeIntervalSinceNow: -86_400)) {
            return "昨日の一歩を完了"
        }
        return "最終実行 \(lastWorkoutDate.replacingOccurrences(of: "-", with: "/"))"
    }

    private static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

enum FriendServiceError: LocalizedError {
    case notConfigured
    case notSignedIn
    case invalidResponse
    case notificationsDenied

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "友達機能の接続準備中です。あとでもう一度お試しください。"
        case .notSignedIn:
            return "接続準備中です。少し待ってからもう一度お試しください。"
        case .invalidResponse:
            return "処理結果を確認できませんでした。もう一度お試しください。"
        case .notificationsDenied:
            return "通知が許可されていません。iPhoneの設定から通知を許可してください。"
        }
    }
}

final class FriendService {
    private lazy var database = Firestore.firestore()
    private lazy var functions = Functions.functions()
    private var tokenObserver: NSObjectProtocol?

    init() {
        tokenObserver = NotificationCenter.default.addObserver(
            forName: .futureBodyFCMTokenUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let token = notification.object as? String else { return }
            Task {
                try? await self?.saveTokenIfAllowed(token)
            }
        }
    }

    deinit {
        if let tokenObserver {
            NotificationCenter.default.removeObserver(tokenObserver)
        }
    }

    func loadProfile() async throws -> (displayName: String, notificationsEnabled: Bool, sharingEnabled: Bool) {
        try ensureConfigured()
        guard let userID = Auth.auth().currentUser?.uid else { throw FriendServiceError.notSignedIn }
        let data = try await database.collection("users").document(userID).getDocument().data() ?? [:]
        let socialSettings = data["socialSettings"] as? [String: Any] ?? [:]
        return (
            displayName: data["displayName"] as? String ?? "あなた",
            notificationsEnabled: socialSettings["friendWorkoutNotifications"] as? Bool ?? false,
            sharingEnabled: socialSettings["sharingEnabled"] as? Bool ?? false
        )
    }

    func updateDisplayName(_ displayName: String) async throws {
        try ensureConfigured()
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...20).contains(trimmed.count) else { throw FriendServiceError.invalidResponse }
        _ = try await call("updateSocialProfile", data: ["displayName": trimmed])
    }

    func createInviteCode() async throws -> String {
        try ensureConfigured()
        let response = try await call("createFriendInvite")
        guard let data = response as? [String: Any], let code = data["code"] as? String else {
            throw FriendServiceError.invalidResponse
        }
        return code
    }

    func acceptInviteCode(_ code: String) async throws {
        try ensureConfigured()
        _ = try await call("acceptFriendInvite", data: ["code": code])
    }

    func setSharingEnabled(_ enabled: Bool) async throws -> Bool {
        try ensureConfigured()
        _ = try await call("setFriendSharingEnabled", data: ["enabled": enabled])
        return enabled
    }

    func removeFriend(_ friendID: String) async throws {
        try ensureConfigured()
        _ = try await call("removeFriend", data: ["friendId": friendID])
    }

    func loadFriends() async throws -> [FriendProfile] {
        try ensureConfigured()
        guard let userID = Auth.auth().currentUser?.uid else { throw FriendServiceError.notSignedIn }
        let friendSnapshot = try await database.collection("users").document(userID).collection("friends")
            .whereField("status", isEqualTo: "accepted")
            .getDocuments()
        return try await withThrowingTaskGroup(of: FriendProfile?.self) { group in
            for friend in friendSnapshot.documents {
                group.addTask { [database] in
                    let profile = try await database.collection("publicProfiles").document(friend.documentID).getDocument()
                    guard let data = profile.data(), data["sharingEnabled"] as? Bool == true else { return nil }
                    return FriendProfile(
                        id: friend.documentID,
                        displayName: data["displayName"] as? String ?? "仲間",
                        currentStreakDays: data["currentStreakDays"] as? Int ?? 0,
                        totalWorkoutDays: data["totalWorkoutDays"] as? Int ?? 0,
                        weeklyWorkoutDays: data["weeklyWorkoutDays"] as? Int ?? 0,
                        lastWorkoutDate: data["lastWorkoutDate"] as? String
                    )
                }
            }

            var profiles: [FriendProfile] = []
            for try await profile in group {
                if let profile { profiles.append(profile) }
            }
            return profiles.sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async throws -> Bool {
        try ensureConfigured()
        guard let userID = Auth.auth().currentUser?.uid else { throw FriendServiceError.notSignedIn }
        if enabled {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { throw FriendServiceError.notificationsDenied }
            Messaging.messaging().isAutoInitEnabled = true
            try await database.collection("users").document(userID).setData([
                "socialSettings": ["friendWorkoutNotifications": true]
            ], merge: true)
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            if let token = await currentFCMToken() {
                try await saveToken(token, userID: userID)
            }
            return true
        }

        Messaging.messaging().isAutoInitEnabled = false
        try await database.collection("users").document(userID).setData([
            "socialSettings": ["friendWorkoutNotifications": false]
        ], merge: true)
        let tokens = try await database.collection("users").document(userID).collection("notificationTokens").getDocuments()
        for token in tokens.documents {
            try await token.reference.delete()
        }
        return false
    }

    func deleteSocialAccount() async throws {
        try ensureConfigured()
        _ = try await call("deleteSocialAccount")
    }

    private func ensureConfigured() throws {
        guard FirebaseApp.app() != nil else { throw FriendServiceError.notConfigured }
    }

    private func saveTokenIfAllowed(_ token: String) async throws {
        guard FirebaseApp.app() != nil else { return }
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let data = try await database.collection("users").document(userID).getDocument().data() ?? [:]
        let settings = data["socialSettings"] as? [String: Any] ?? [:]
        guard settings["friendWorkoutNotifications"] as? Bool == true else { return }
        try await saveToken(token, userID: userID)
    }

    private func saveToken(_ token: String, userID: String) async throws {
        let digest = SHA256.hash(data: Data(token.utf8))
        let tokenID = digest.map { String(format: "%02x", $0) }.joined()
        try await database.collection("users").document(userID).collection("notificationTokens").document(tokenID).setData([
            "token": token,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)
    }

    private func currentFCMToken() async -> String? {
        await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, _ in
                continuation.resume(returning: token)
            }
        }
    }

    private func call(_ name: String, data: [String: Any] = [:]) async throws -> Any {
        try await withCheckedThrowingContinuation { continuation in
            functions.httpsCallable(name).call(data) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data = result?.data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: [:])
                }
            }
        }
    }
}

@MainActor
final class FriendsStore: ObservableObject {
    @Published private(set) var friends: [FriendProfile] = []
    @Published private(set) var displayName = "あなた"
    @Published private(set) var notificationsEnabled = false
    @Published private(set) var sharingEnabled = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: FriendService

    init(service: FriendService = FriendService()) {
        self.service = service
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let profile = service.loadProfile()
            async let loadedFriends = service.loadFriends()
            let (loadedProfile, profiles) = try await (profile, loadedFriends)
            displayName = loadedProfile.displayName
            notificationsEnabled = loadedProfile.notificationsEnabled
            sharingEnabled = loadedProfile.sharingEnabled
            friends = profiles
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDisplayName(_ value: String) async {
        do {
            try await service.updateDisplayName(value)
            displayName = value.trimmingCharacters(in: .whitespacesAndNewlines)
            errorMessage = nil
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createInviteCode() async -> String? {
        do {
            let code = try await service.createInviteCode()
            errorMessage = nil
            return code
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func acceptInviteCode(_ code: String) async {
        do {
            try await service.acceptInviteCode(code)
            await reload()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        do {
            notificationsEnabled = try await service.setNotificationsEnabled(enabled)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setSharingEnabled(_ enabled: Bool) async {
        do {
            sharingEnabled = try await service.setSharingEnabled(enabled)
            errorMessage = nil
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(_ friend: FriendProfile) async {
        do {
            try await service.removeFriend(friend.id)
            friends.removeAll { $0.id == friend.id }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
