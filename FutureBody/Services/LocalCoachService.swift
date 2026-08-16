import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum CoachMessageSource: String, Codable, Equatable {
    case onDevice
    case fallback
    case safety
}

struct LocalCoachResult: Equatable {
    let message: String
    let source: CoachMessageSource
}

enum LocalCoachService {
    static func makeMessage(
        state: DailyState,
        plan: WorkoutPlan,
        records: [WorkoutRecord]
    ) async -> LocalCoachResult {
        let fallback = LocalCoachMessage.make(state: state, plan: plan)

        guard state.bodyStatus != .pain else {
            return LocalCoachResult(
                message: fallback,
                source: .safety
            )
        }

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
            let session = LanguageModelSession(instructions: instructions)
            do {
                let response = try await session.respond(to: prompt(state: state, plan: plan, records: records))
                if let message = safeMessage(response.content) {
                    return LocalCoachResult(message: message, source: .onDevice)
                }
            } catch {
            }
        }
        #endif

        return LocalCoachResult(message: fallback, source: .fallback)
    }

    private static let instructions = """
    あなたはRe:BodyのiPhone内AIコーチです。
    忙しい人が自由時間を失わず、今日のトレーニングを始めやすくなる短い一言を日本語で返してください。
    入力された状態と最近の実行履歴だけを使い、人格を評価しないでください。
    痛みの診断や治療、無理な運動、食事や体重の断定はしないでください。
    既存のメニューや種目を変更せず、70文字以内の自然な日本語を1文だけ返してください。
    """

    private static func prompt(state: DailyState, plan: WorkoutPlan, records: [WorkoutRecord]) -> String {
        let recent = records
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(8)
            .map { record in
                "\(record.sessionType.rawValue),\(record.durationMinutes)分"
            }
            .joined(separator: " / ")

        return """
        今日の状態:
        目的: \(state.focus.title)
        使える時間: \(state.availableMinutes)分
        疲れ具合: \(state.energy.title)
        身体の状態: \(state.bodyStatus.title)
        中断の可能性: \(state.interruptionRisk ? "あり" : "なし")
        提案メニュー: \(plan.title)
        最近の実行: \(recent.isEmpty ? "まだ記録なし" : recent)

        この人が今すぐ始めやすくなる一言を返してください。
        """
    }

    private static func safeMessage(_ value: String) -> String? {
        let message = value
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !message.isEmpty, message.count <= 120 else { return nil }

        let unsafeTerms = ["診断", "治療", "薬を", "薬の", "医師になりすます"]
        guard !unsafeTerms.contains(where: message.contains) else { return nil }
        return message
    }
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
