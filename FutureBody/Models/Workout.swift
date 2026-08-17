import Foundation

enum SessionType: String, Codable, CaseIterable, Identifiable, Equatable {
    case rescue
    case standard
    case extended

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rescue:
            return "2分の起動"
        case .standard:
            return "10分の土台づくり"
        case .extended:
            return "15分以上の伸ばす時間"
        }
    }

    var minutes: Int {
        switch self {
        case .rescue:
            return 2
        case .standard:
            return 10
        case .extended:
            return 15
        }
    }

    var durationLabel: String {
        switch self {
        case .rescue:
            return "2分"
        case .standard:
            return "10分"
        case .extended:
            return "15分以上"
        }
    }

    var rounds: Int {
        switch self {
        case .rescue:
            return 1
        case .standard:
            return 2
        case .extended:
            return 3
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case low
    case normal
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low:
            return "疲れている"
        case .normal:
            return "普通"
        case .high:
            return "少し余裕がある"
        }
    }
}

enum BodyStatus: String, Codable, CaseIterable, Identifiable {
    case good
    case sensitive
    case pain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .good:
            return "痛みなし"
        case .sensitive:
            return "違和感がある"
        case .pain:
            return "痛みがある"
        }
    }
}

enum FocusArea: String, Codable, CaseIterable, Identifiable {
    case appearance
    case upperBody
    case ability
    case balanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance:
            return "お腹・見た目"
        case .upperBody:
            return "胸・腕の厚み"
        case .ability:
            return "動く・支える"
        case .balanced:
            return "全体を底上げ"
        }
    }

    var detail: String {
        switch self {
        case .appearance:
            return "お腹まわりを整え、Tシャツが似合う土台へ"
        case .upperBody:
            return "胸と腕を使い、上半身の存在感をつくる"
        case .ability:
            return "テニスや抱っこにつながる脚・お尻・体幹を育てる"
        case .balanced:
            return "見た目と動ける力をまとめて伸ばす"
        }
    }

    var icon: String {
        switch self {
        case .appearance:
            return "tshirt"
        case .upperBody:
            return "figure.strengthtraining.functional"
        case .ability:
            return "figure.run"
        case .balanced:
            return "arrow.up.forward"
        }
    }
}

struct DailyState: Codable, Equatable {
    var availableMinutes: Int
    var energy: EnergyLevel
    var bodyStatus: BodyStatus
    var interruptionRisk: Bool
    var focus: FocusArea

    init(
        availableMinutes: Int = 10,
        energy: EnergyLevel = .normal,
        bodyStatus: BodyStatus = .good,
        interruptionRisk: Bool = true,
        focus: FocusArea = .appearance
    ) {
        self.availableMinutes = availableMinutes
        self.energy = energy
        self.bodyStatus = bodyStatus
        self.interruptionRisk = interruptionRisk
        self.focus = focus
    }

    private enum CodingKeys: String, CodingKey {
        case availableMinutes
        case energy
        case bodyStatus
        case interruptionRisk
        case focus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        availableMinutes = try container.decodeIfPresent(Int.self, forKey: .availableMinutes) ?? 10
        energy = try container.decodeIfPresent(EnergyLevel.self, forKey: .energy) ?? .normal
        bodyStatus = try container.decodeIfPresent(BodyStatus.self, forKey: .bodyStatus) ?? .good
        interruptionRisk = try container.decodeIfPresent(Bool.self, forKey: .interruptionRisk) ?? true
        focus = try container.decodeIfPresent(FocusArea.self, forKey: .focus) ?? .appearance
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(availableMinutes, forKey: .availableMinutes)
        try container.encode(energy, forKey: .energy)
        try container.encode(bodyStatus, forKey: .bodyStatus)
        try container.encode(interruptionRisk, forKey: .interruptionRisk)
        try container.encode(focus, forKey: .focus)
    }
}

struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let detail: String
    let purpose: String
    let steps: [String]
    let keyPoint: String
    let target: String
    let systemImage: String
}

struct WorkoutPlan: Identifiable, Codable, Hashable {
    let id: String
    let type: SessionType
    let focus: FocusArea
    let rounds: Int
    let variation: Int
    let title: String
    let subtitle: String
    let exercises: [Exercise]

    var format: String {
        "\(rounds)周 × \(exercises.count)種目"
    }
}

struct WorkoutRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let planID: String
    let sessionType: SessionType
    let completedAt: Date
    let durationMinutes: Int
}

enum WorkoutCatalog {
    static let variationCount = 3
    static let rescue = plan(for: .appearance, type: .rescue)
    static let standard = plan(for: .appearance, type: .standard)
    static let extended = plan(for: .appearance, type: .extended)
    static let all: [WorkoutPlan] = FocusArea.allCases.flatMap { focus in
        SessionType.allCases.flatMap { type in
            (0..<variationCount).map { variation in
                plan(for: focus, type: type, variation: variation)
            }
        }
    }

    static func plan(for focus: FocusArea, type: SessionType, variation: Int = 0) -> WorkoutPlan {
        let normalizedVariation = ((variation % variationCount) + variationCount) % variationCount
        return WorkoutPlan(
            id: "\(focus.rawValue)-\(type.rawValue)-v\(normalizedVariation)",
            type: type,
            focus: focus,
            rounds: type.rounds,
            variation: normalizedVariation,
            title: title(for: focus, type: type, variation: normalizedVariation),
            subtitle: subtitle(for: focus, type: type, variation: normalizedVariation),
            exercises: exercises(for: focus, type: type, variation: normalizedVariation)
        )
    }

    private static func title(for focus: FocusArea, type: SessionType, variation: Int) -> String {
        let baseTitle: String
        switch (focus, type) {
        case (.appearance, .rescue):
            baseTitle = "お腹と胸を2分で起こす"
        case (.appearance, .standard):
            baseTitle = "お腹まわりを整える10分"
        case (.appearance, .extended):
            baseTitle = "見た目の土台を伸ばす15分以上"
        case (.upperBody, .rescue):
            baseTitle = "胸と腕を2分で起こす"
        case (.upperBody, .standard):
            baseTitle = "胸と腕を育てる10分"
        case (.upperBody, .extended):
            baseTitle = "上半身の存在感を伸ばす15分以上"
        case (.ability, .rescue):
            baseTitle = "動ける身体を2分で起こす"
        case (.ability, .standard):
            baseTitle = "動く・支える力を育てる10分"
        case (.ability, .extended):
            baseTitle = "テニスと抱っこを支える15分以上"
        case (.balanced, .rescue):
            baseTitle = "魅力と能力を2分で起こす"
        case (.balanced, .standard):
            baseTitle = "魅力と能力の土台をつくる10分"
        case (.balanced, .extended):
            baseTitle = "魅力と能力を伸ばす15分以上"
        }

        switch variation {
        case 1:
            return "\(baseTitle)・ゆっくり整える"
        case 2:
            return "\(baseTitle)・動きを広げる"
        default:
            return baseTitle
        }
    }

    private static func subtitle(for focus: FocusArea, type: SessionType, variation: Int) -> String {
        let baseSubtitle: String
        switch focus {
        case .appearance:
            baseSubtitle = type == .rescue ? "胸を押し、お腹を締める。まずは見た目の土台から" : "胸・脚・お腹を順番に使い、お腹まわりが整う土台をつくる"
        case .upperBody:
            baseSubtitle = type == .rescue ? "胸を押す動きを2分だけ。細い腕と薄い胸を変える一歩" : "胸・肩・腕を順番に使い、上半身に厚みをつくる"
        case .ability:
            baseSubtitle = type == .rescue ? "しゃがむ・支えるを2分だけ。動ける身体を切らさない" : "脚・お尻・お腹を使い、テニスや抱っこを支える力を育てる"
        case .balanced:
            baseSubtitle = type == .rescue ? "見た目と動ける力を、2分の一歩でつなぐ" : "押す・しゃがむ・支えるをまとめて、全身を伸ばす"
        }

        if variation == 1 && type != .rescue {
            return "フォームを丁寧に。\(baseSubtitle)"
        }
        if variation == 2 && type != .rescue {
            return "動きを変えて飽きずに。\(baseSubtitle)"
        }
        return baseSubtitle
    }

    private static func exercises(for focus: FocusArea, type: SessionType, variation: Int) -> [Exercise] {
        switch (focus, type, variation) {
        case (.appearance, .rescue, 0):
            return [kneePushup(id: "appearance-rescue-push", target: "5〜8回"), deadBug(id: "appearance-rescue-deadbug", target: "左右6回")]
        case (.appearance, .rescue, 1):
            return [inclinePushup(id: "appearance-rescue-incline", target: "8〜10回"), birdDog(id: "appearance-rescue-bird-dog", target: "左右6回")]
        case (.appearance, .rescue, _):
            return [squat(id: "appearance-rescue-squat", target: "10回"), hipBridge(id: "appearance-rescue-bridge", target: "10回")]
        case (.appearance, .standard, 0):
            return [pushup(id: "appearance-standard-push", target: "8〜12回"), reverseLunge(id: "appearance-standard-lunge", target: "左右8回"), deadBug(id: "appearance-standard-deadbug", target: "左右8回"), hipBridge(id: "appearance-standard-bridge", target: "12回")]
        case (.appearance, .standard, 1):
            return [tempoPushup(id: "appearance-standard-tempo-push", target: "6〜10回"), splitSquat(id: "appearance-standard-split", target: "左右8回"), sidePlank(id: "appearance-standard-side", target: "左右20秒"), birdDog(id: "appearance-standard-bird-dog", target: "左右8回")]
        case (.appearance, .standard, _):
            return [inclinePushup(id: "appearance-standard-incline", target: "10〜15回"), lateralLunge(id: "appearance-standard-lateral", target: "左右8回"), hipBridge(id: "appearance-standard-bridge", target: "12回"), deadBug(id: "appearance-standard-deadbug", target: "左右8回")]
        case (.appearance, .extended, 0):
            return [pushup(id: "appearance-extended-push", target: "8〜12回"), pikePushup(id: "appearance-extended-pike", target: "6〜10回"), reverseLunge(id: "appearance-extended-lunge", target: "左右8回"), deadBug(id: "appearance-extended-deadbug", target: "左右10回"), hipBridge(id: "appearance-extended-bridge", target: "15回")]
        case (.appearance, .extended, 1):
            return [narrowPushup(id: "appearance-extended-narrow", target: "6〜10回"), squat(id: "appearance-extended-squat", target: "12回"), sidePlank(id: "appearance-extended-side", target: "左右25秒"), birdDog(id: "appearance-extended-bird-dog", target: "左右10回")]
        case (.appearance, .extended, _):
            return [tempoPushup(id: "appearance-extended-tempo-push", target: "6〜10回"), lateralLunge(id: "appearance-extended-lateral", target: "左右10回"), singleLegBridge(id: "appearance-extended-single-bridge", target: "左右10回"), deadBug(id: "appearance-extended-deadbug", target: "左右10回")]
        case (.upperBody, .rescue, 0):
            return [kneePushup(id: "upper-rescue-push", target: "5〜8回"), narrowPushup(id: "upper-rescue-narrow", target: "3〜5回")]
        case (.upperBody, .rescue, 1):
            return [inclinePushup(id: "upper-rescue-incline", target: "8〜10回"), proneYTW(id: "upper-rescue-ytw", target: "各3回")]
        case (.upperBody, .rescue, _):
            return [kneePushup(id: "upper-rescue-knee", target: "5〜8回"), birdDog(id: "upper-rescue-bird-dog", target: "左右6回")]
        case (.upperBody, .standard, 0):
            return [pushup(id: "upper-standard-push", target: "8〜12回"), narrowPushup(id: "upper-standard-narrow", target: "5〜8回"), pikePushup(id: "upper-standard-pike", target: "6〜10回"), deadBug(id: "upper-standard-deadbug", target: "左右8回")]
        case (.upperBody, .standard, 1):
            return [tempoPushup(id: "upper-standard-tempo-push", target: "6〜10回"), inclinePushup(id: "upper-standard-incline", target: "10〜15回"), proneYTW(id: "upper-standard-ytw", target: "各5回"), sidePlank(id: "upper-standard-side", target: "左右20秒")]
        case (.upperBody, .standard, _):
            return [pushup(id: "upper-standard-push", target: "8〜12回"), pikePushup(id: "upper-standard-pike", target: "6〜10回"), proneYTW(id: "upper-standard-ytw", target: "各5回"), birdDog(id: "upper-standard-bird-dog", target: "左右8回")]
        case (.upperBody, .extended, 0):
            return [pushup(id: "upper-extended-push", target: "8〜12回"), pikePushup(id: "upper-extended-pike", target: "6〜10回"), narrowPushup(id: "upper-extended-narrow", target: "5〜8回"), reverseLunge(id: "upper-extended-lunge", target: "左右8回"), deadBug(id: "upper-extended-deadbug", target: "左右10回")]
        case (.upperBody, .extended, 1):
            return [tempoPushup(id: "upper-extended-tempo-push", target: "6〜10回"), inclinePushup(id: "upper-extended-incline", target: "10〜15回"), proneYTW(id: "upper-extended-ytw", target: "各6回"), sidePlank(id: "upper-extended-side", target: "左右25秒")]
        case (.upperBody, .extended, _):
            return [pushup(id: "upper-extended-push", target: "8〜12回"), narrowPushup(id: "upper-extended-narrow", target: "5〜8回"), proneYTW(id: "upper-extended-ytw", target: "各6回"), reverseLunge(id: "upper-extended-lunge", target: "左右10回")]
        case (.ability, .rescue, 0):
            return [squat(id: "ability-rescue-squat", target: "10回"), deadBug(id: "ability-rescue-deadbug", target: "左右6回")]
        case (.ability, .rescue, 1):
            return [hipBridge(id: "ability-rescue-bridge", target: "10回"), birdDog(id: "ability-rescue-bird-dog", target: "左右6回")]
        case (.ability, .rescue, _):
            return [calfRaise(id: "ability-rescue-calf", target: "15回"), sidePlank(id: "ability-rescue-side", target: "左右15秒")]
        case (.ability, .standard, 0):
            return [squat(id: "ability-standard-squat", target: "12回"), reverseLunge(id: "ability-standard-lunge", target: "左右8回"), hipBridge(id: "ability-standard-bridge", target: "12回"), deadBug(id: "ability-standard-deadbug", target: "左右8回")]
        case (.ability, .standard, 1):
            return [splitSquat(id: "ability-standard-split", target: "左右8回"), lateralLunge(id: "ability-standard-lateral", target: "左右8回"), birdDog(id: "ability-standard-bird-dog", target: "左右8回"), hipBridge(id: "ability-standard-bridge", target: "12回")]
        case (.ability, .standard, _):
            return [squat(id: "ability-standard-squat", target: "12回"), singleLegBridge(id: "ability-standard-single-bridge", target: "左右8回"), sidePlank(id: "ability-standard-side", target: "左右20秒"), calfRaise(id: "ability-standard-calf", target: "15回")]
        case (.ability, .extended, 0):
            return [squat(id: "ability-extended-squat", target: "15回"), reverseLunge(id: "ability-extended-lunge", target: "左右10回"), hipBridge(id: "ability-extended-bridge", target: "15回"), sidePlank(id: "ability-extended-side", target: "左右20秒"), deadBug(id: "ability-extended-deadbug", target: "左右10回")]
        case (.ability, .extended, 1):
            return [splitSquat(id: "ability-extended-split", target: "左右10回"), lateralLunge(id: "ability-extended-lateral", target: "左右10回"), birdDog(id: "ability-extended-bird-dog", target: "左右10回"), deadBug(id: "ability-extended-deadbug", target: "左右10回")]
        case (.ability, .extended, _):
            return [squat(id: "ability-extended-squat", target: "15回"), singleLegBridge(id: "ability-extended-single-bridge", target: "左右10回"), reverseLunge(id: "ability-extended-lunge", target: "左右10回"), calfRaise(id: "ability-extended-calf", target: "20回")]
        case (.balanced, .rescue, 0):
            return [kneePushup(id: "balanced-rescue-push", target: "5〜8回"), squat(id: "balanced-rescue-squat", target: "10回")]
        case (.balanced, .rescue, 1):
            return [inclinePushup(id: "balanced-rescue-incline", target: "8〜10回"), birdDog(id: "balanced-rescue-bird-dog", target: "左右6回")]
        case (.balanced, .rescue, _):
            return [squat(id: "balanced-rescue-squat", target: "10回"), hipBridge(id: "balanced-rescue-bridge", target: "10回")]
        case (.balanced, .standard, 0):
            return [pushup(id: "balanced-standard-push", target: "8〜12回"), squat(id: "balanced-standard-squat", target: "12回"), deadBug(id: "balanced-standard-deadbug", target: "左右8回"), hipBridge(id: "balanced-standard-bridge", target: "12回")]
        case (.balanced, .standard, 1):
            return [inclinePushup(id: "balanced-standard-incline", target: "10〜15回"), reverseLunge(id: "balanced-standard-lunge", target: "左右8回"), proneYTW(id: "balanced-standard-ytw", target: "各5回"), birdDog(id: "balanced-standard-bird-dog", target: "左右8回")]
        case (.balanced, .standard, _):
            return [tempoPushup(id: "balanced-standard-tempo-push", target: "6〜10回"), lateralLunge(id: "balanced-standard-lateral", target: "左右8回"), sidePlank(id: "balanced-standard-side", target: "左右20秒"), hipBridge(id: "balanced-standard-bridge", target: "12回")]
        case (.balanced, .extended, 0):
            return [pushup(id: "balanced-extended-push", target: "8〜12回"), reverseLunge(id: "balanced-extended-lunge", target: "左右8回"), pikePushup(id: "balanced-extended-pike", target: "6〜10回"), deadBug(id: "balanced-extended-deadbug", target: "左右10回"), hipBridge(id: "balanced-extended-bridge", target: "15回")]
        case (.balanced, .extended, 1):
            return [narrowPushup(id: "balanced-extended-narrow", target: "5〜8回"), squat(id: "balanced-extended-squat", target: "15回"), proneYTW(id: "balanced-extended-ytw", target: "各6回"), sidePlank(id: "balanced-extended-side", target: "左右25秒")]
        case (.balanced, .extended, _):
            return [tempoPushup(id: "balanced-extended-tempo-push", target: "6〜10回"), splitSquat(id: "balanced-extended-split", target: "左右10回"), singleLegBridge(id: "balanced-extended-single-bridge", target: "左右10回"), birdDog(id: "balanced-extended-bird-dog", target: "左右10回")]
        }
    }

    private static func kneePushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "ひざつきプッシュアップ", detail: "ひざを床につき、胸を手の間へ下ろす", purpose: "胸・腕", steps: ["手を肩幅より少し広く置き、ひざを床につく", "頭からひざまでを一直線にして、胸をゆっくり下ろす", "床を押して、腕を伸ばしきる手前まで戻る"], keyPoint: "腰を反らさず、胸で床を押す", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func inclinePushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "壁プッシュアップ", detail: "壁を押して、胸と腕を安全に使う", purpose: "胸・腕", steps: ["壁から一歩離れて立ち、手を肩幅で壁につく", "身体を一直線に保ち、胸を壁へゆっくり近づける", "手のひらで壁を押して、まっすぐ戻る"], keyPoint: "腰を反らさず、胸から壁へ近づく", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func pushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "プッシュアップ", detail: "胸をゆっくり下げ、床を押して戻る", purpose: "胸・腕・体幹", steps: ["手を肩幅より少し広く置き、身体を一直線にする", "ひじを斜め後ろへ引きながら、胸をゆっくり下ろす", "床を強く押して、身体を一直線に戻す"], keyPoint: "腰を落とさず、胸を手の間へ運ぶ", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func tempoPushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "ゆっくりプッシュアップ", detail: "下げる動きを3秒かけて、胸に負荷を集める", purpose: "胸・腕・体幹", steps: ["手を肩幅より少し広く置き、身体を一直線にする", "3秒かけて胸をゆっくり下ろす", "床を押して、身体を一直線に戻る"], keyPoint: "回数よりも、毎回同じ速さで動く", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func narrowPushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "手幅せまめプッシュアップ", detail: "手幅を少し狭くして、腕の裏まで使う", purpose: "腕・胸", steps: ["手を肩幅より少し狭く置き、身体を一直線にする", "ひじを身体の近くに保ち、胸をゆっくり下ろす", "床を押して、腕の裏を使いながら戻る"], keyPoint: "ひじを開きすぎず、反動を使わない", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func pikePushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "パイクプッシュアップ", detail: "お尻を高くして、頭を床へ近づける", purpose: "肩・胸・腕", steps: ["手を肩幅に置き、お尻を高くして身体を山形にする", "ひじを斜め後ろへ引き、頭を手の前へゆっくり下ろす", "手で床を押して、山形の姿勢へ戻る"], keyPoint: "肩に違和感があれば、ひざつきプッシュアップに替える", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func squat(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "スクワット", detail: "お尻を後ろへ引き、足の裏で立ち上がる", purpose: "脚・お尻", steps: ["足を肩幅に開き、つま先を少し外へ向ける", "お尻を後ろへ引き、椅子に座るように腰を下ろす", "足の裏で床を押して、まっすぐ立つ"], keyPoint: "ひざをつま先と同じ向きに保つ", target: target, systemImage: "figure.strengthtraining.traditional")
    }

    private static func reverseLunge(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "リバースランジ", detail: "後ろへ一歩引き、前の足で戻る", purpose: "脚・お尻・バランス", steps: ["足を腰幅に開き、背すじを伸ばして立つ", "片足を後ろへ引き、前のひざを軽く曲げる", "前の足で床を押して、立った姿勢へ戻る"], keyPoint: "前のひざを内側へ倒さず、上体を起こす", target: target, systemImage: "figure.strengthtraining.traditional")
    }

    private static func splitSquat(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "スプリットスクワット", detail: "足を前後に置き、その場で脚を曲げ伸ばす", purpose: "脚・お尻・バランス", steps: ["足を前後に開き、つま先を正面へ向ける", "前の足に体重を乗せ、両ひざをゆっくり曲げる", "前の足で床を押して戻り、反対側も行う"], keyPoint: "前のひざとつま先を同じ向きに保つ", target: target, systemImage: "figure.strengthtraining.traditional")
    }

    private static func lateralLunge(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "サイドランジ", detail: "横へ踏み出し、お尻を後ろへ引いて戻る", purpose: "脚・お尻・横の動き", steps: ["足をそろえて立ち、背すじを伸ばす", "片足を横へ大きく踏み出し、お尻を後ろへ引く", "踏み出した足で床を押し、真ん中へ戻る"], keyPoint: "曲げたひざをつま先と同じ向きに保つ", target: target, systemImage: "figure.strengthtraining.traditional")
    }

    private static func deadBug(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "デッドバグ", detail: "腰を床につけたまま、手足をゆっくり動かす", purpose: "お腹・体幹", steps: ["仰向けでひざを90度に曲げ、腕を天井へ伸ばす", "腰を床に軽くつけたまま、片手と反対の脚を伸ばす", "戻してから反対側も行い、左右を交互に繰り返す"], keyPoint: "腰が浮く手前で止め、呼吸を止めない", target: target, systemImage: "figure.core.training")
    }

    private static func birdDog(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "バードドッグ", detail: "四つ這いで、手足をゆっくり遠くへ伸ばす", purpose: "お腹・背中・バランス", steps: ["四つ這いで、手を肩の真下、ひざを股関節の真下に置く", "片手と反対の脚を、身体がぶれない範囲で伸ばす", "ゆっくり戻して、反対側も行う"], keyPoint: "腰を反らず、頭から脚までを長く保つ", target: target, systemImage: "figure.core.training")
    }

    private static func proneYTW(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "うつぶせY-T-W", detail: "うつぶせで腕の形を変え、背中を使う", purpose: "背中・肩", steps: ["うつぶせで額をタオルに置き、腕をYの形に伸ばす", "肩をすくめずに腕を少し浮かせ、T、Wの形へゆっくり変える", "反動を使わず、腕を下ろして休む"], keyPoint: "腰で反らず、肩甲骨を背中の中央へ寄せる", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func hipBridge(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "ヒップリフト", detail: "お尻を締めて、ゆっくり持ち上げる", purpose: "お尻・体幹", steps: ["仰向けでひざを立て、足を腰幅に置く", "かかとで床を押し、お尻をゆっくり持ち上げる", "お尻を締めたら、背中から順番にゆっくり下ろす"], keyPoint: "腰を反らず、お尻で持ち上げる", target: target, systemImage: "figure.core.training")
    }

    private static func singleLegBridge(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "片脚ヒップリフト", detail: "片脚ずつ、お尻を締めて持ち上げる", purpose: "お尻・脚・体幹", steps: ["仰向けでひざを立て、片脚を軽く浮かせる", "床についている足のかかとで押し、お尻を持ち上げる", "ゆっくり下ろしてから、反対側も行う"], keyPoint: "骨盤を傾けず、腰が痛くなる前に止める", target: target, systemImage: "figure.core.training")
    }

    private static func calfRaise(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "カーフレイズ", detail: "足の親指のつけ根で床を押し、かかとを上げる", purpose: "ふくらはぎ・足首", steps: ["足を腰幅に開き、壁に指を添えて立つ", "足の親指のつけ根で床を押し、かかとをゆっくり上げる", "一番上で一度止まり、ゆっくり下ろす"], keyPoint: "足首を外へ倒さず、まっすぐ上下する", target: target, systemImage: "figure.strengthtraining.traditional")
    }

    private static func sidePlank(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "サイドプランク", detail: "身体を横向きにして、一直線を保つ", purpose: "脇腹・体幹", steps: ["横向きでひじを肩の真下につき、ひざを曲げる", "腰を持ち上げ、頭からひざまでを一直線にする", "呼吸を続けながら姿勢を保ち、反対側も行う"], keyPoint: "腰が落ちる前に終え、痛みがあれば中止する", target: target, systemImage: "figure.core.training")
    }
}
