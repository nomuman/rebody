import FirebaseFunctions
import Foundation

enum CoachMessageSource: String, Codable, Equatable {
    case ai
    case fallback
    case safety
    case rateLimited
}

struct CoachMessageRequest: Encodable {
    let availableMinutes: Int
    let energy: String
    let bodyStatus: String
    let interruptionRisk: Bool
    let focus: String
    let recommendedPlanID: String
    let recentSessions: [RecentSession]

    struct RecentSession: Encodable {
        let sessionType: String
        let durationMinutes: Int
        let daysAgo: Int
    }
}

struct CoachMessageResponse: Decodable {
    let message: String
    let source: CoachMessageSource
}

final class FirebaseCoachService {
    private let callable = Functions.functions(region: "asia-northeast1").httpsCallable("generateCoachMessage")

    func request(_ request: CoachMessageRequest) async throws -> CoachMessageResponse {
        let payload = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(request),
            options: [.fragmentsAllowed]
        )

        let result = try await callable.call(payload)

        let data = try JSONSerialization.data(withJSONObject: result.data)
        return try JSONDecoder().decode(CoachMessageResponse.self, from: data)
    }
}

enum FirebaseCoachError: Error {
    case emptyResponse
}

enum LocalCoachMessage {
    static func make(state: DailyState, plan: WorkoutPlan) -> String {
        if state.bodyStatus == .pain {
            return "痛みがある日は休むのが、魅力と能力を守る今日の一手です。"
        }

        if state.interruptionRisk || state.availableMinutes <= 2 || state.energy == .low {
            return "今日は2分で十分。自由時間の前に、未来の自分へ一歩だけ渡しましょう。"
        }

        switch state.focus {
        case .appearance:
            return "お腹まわりを整える一回を、胸と体幹の土台づくりとして始めましょう。"
        case .upperBody:
            return "胸と腕の厚みは、今日の一回を積み重ねた先で少しずつ戻ってきます。"
        case .ability:
            return "テニスと抱っこを支える力は、脚と体幹の短い一回から育ちます。"
        case .balanced:
            return "見た目と動ける力を、今日できる分だけ更新してから自分の時間へ戻りましょう。"
        }
    }
}
