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
            return "15分の伸ばす時間"
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
    let title: String
    let subtitle: String
    let exercises: [Exercise]
}

struct WorkoutRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let planID: String
    let sessionType: SessionType
    let completedAt: Date
    let durationMinutes: Int
}

enum WorkoutCatalog {
    static let rescue = plan(for: .appearance, type: .rescue)
    static let standard = plan(for: .appearance, type: .standard)
    static let extended = plan(for: .appearance, type: .extended)
    static let all: [WorkoutPlan] = FocusArea.allCases.flatMap { focus in
        SessionType.allCases.map { type in
            plan(for: focus, type: type)
        }
    }

    static func plan(for focus: FocusArea, type: SessionType) -> WorkoutPlan {
        WorkoutPlan(
            id: "(focus.rawValue)-(type.rawValue)",
            type: type,
            focus: focus,
            title: title(for: focus, type: type),
            subtitle: subtitle(for: focus, type: type),
            exercises: exercises(for: focus, type: type)
        )
    }

    private static func title(for focus: FocusArea, type: SessionType) -> String {
        switch (focus, type) {
        case (.appearance, .rescue):
            return "お腹と胸を2分で起こす"
        case (.appearance, .standard):
            return "お腹まわりを整える10分"
        case (.appearance, .extended):
            return "見た目の土台を伸ばす15分"
        case (.upperBody, .rescue):
            return "胸と腕を2分で起こす"
        case (.upperBody, .standard):
            return "胸と腕を育てる10分"
        case (.upperBody, .extended):
            return "上半身の存在感を伸ばす15分"
        case (.ability, .rescue):
            return "動ける身体を2分で起こす"
        case (.ability, .standard):
            return "動く・支える力を育てる10分"
        case (.ability, .extended):
            return "テニスと抱っこを支える15分"
        case (.balanced, .rescue):
            return "魅力と能力を2分で起こす"
        case (.balanced, .standard):
            return "魅力と能力の土台をつくる10分"
        case (.balanced, .extended):
            return "魅力と能力を伸ばす15分"
        }
    }

    private static func subtitle(for focus: FocusArea, type: SessionType) -> String {
        switch focus {
        case .appearance:
            return type == .rescue ? "胸を押し、お腹を締める。まずは見た目の土台から" : "胸・脚・お腹を順番に使い、お腹まわりが整う土台をつくる"
        case .upperBody:
            return type == .rescue ? "胸を押す動きを2分だけ。細い腕と薄い胸を変える一歩" : "押す動きを重ねて、胸と腕に少しずつ厚みをつくる"
        case .ability:
            return type == .rescue ? "しゃがむ・支えるを2分だけ。動ける身体を切らさない" : "脚・お尻・お腹を使い、テニスや抱っこを支える力を育てる"
        case .balanced:
            return type == .rescue ? "見た目と動ける力を、2分の一歩でつなぐ" : "見た目と動ける力を、無理のない順番でまとめて伸ばす"
        }
    }

    private static func exercises(for focus: FocusArea, type: SessionType) -> [Exercise] {
        switch (focus, type) {
        case (.appearance, .rescue):
            return [kneePushup(id: "appearance-rescue-push", target: "5〜8回"), deadBug(id: "appearance-rescue-deadbug", target: "左右6回")]
        case (.appearance, .standard):
            return [pushup(id: "appearance-standard-push", target: "8〜12回"), reverseLunge(id: "appearance-standard-lunge", target: "左右8回"), deadBug(id: "appearance-standard-deadbug", target: "左右8回"), hipBridge(id: "appearance-standard-bridge", target: "12回")]
        case (.appearance, .extended):
            return [pushup(id: "appearance-extended-push", target: "8〜12回"), pikePushup(id: "appearance-extended-pike", target: "6〜10回"), reverseLunge(id: "appearance-extended-lunge", target: "左右8回"), deadBug(id: "appearance-extended-deadbug", target: "左右10回"), hipBridge(id: "appearance-extended-bridge", target: "15回")]
        case (.upperBody, .rescue):
            return [kneePushup(id: "upper-rescue-push", target: "5〜8回"), narrowPushup(id: "upper-rescue-narrow", target: "3〜5回")]
        case (.upperBody, .standard):
            return [pushup(id: "upper-standard-push", target: "8〜12回"), narrowPushup(id: "upper-standard-narrow", target: "5〜8回"), pikePushup(id: "upper-standard-pike", target: "6〜10回"), deadBug(id: "upper-standard-deadbug", target: "左右8回")]
        case (.upperBody, .extended):
            return [pushup(id: "upper-extended-push", target: "8〜12回"), pikePushup(id: "upper-extended-pike", target: "6〜10回"), narrowPushup(id: "upper-extended-narrow", target: "5〜8回"), reverseLunge(id: "upper-extended-lunge", target: "左右8回"), deadBug(id: "upper-extended-deadbug", target: "左右10回")]
        case (.ability, .rescue):
            return [squat(id: "ability-rescue-squat", target: "10回"), deadBug(id: "ability-rescue-deadbug", target: "左右6回")]
        case (.ability, .standard):
            return [squat(id: "ability-standard-squat", target: "12回"), reverseLunge(id: "ability-standard-lunge", target: "左右8回"), hipBridge(id: "ability-standard-bridge", target: "12回"), deadBug(id: "ability-standard-deadbug", target: "左右8回")]
        case (.ability, .extended):
            return [squat(id: "ability-extended-squat", target: "15回"), reverseLunge(id: "ability-extended-lunge", target: "左右10回"), hipBridge(id: "ability-extended-bridge", target: "15回"), sidePlank(id: "ability-extended-side", target: "左右20秒"), deadBug(id: "ability-extended-deadbug", target: "左右10回")]
        case (.balanced, .rescue):
            return [kneePushup(id: "balanced-rescue-push", target: "5〜8回"), squat(id: "balanced-rescue-squat", target: "10回")]
        case (.balanced, .standard):
            return [pushup(id: "balanced-standard-push", target: "8〜12回"), squat(id: "balanced-standard-squat", target: "12回"), deadBug(id: "balanced-standard-deadbug", target: "左右8回"), hipBridge(id: "balanced-standard-bridge", target: "12回")]
        case (.balanced, .extended):
            return [pushup(id: "balanced-extended-push", target: "8〜12回"), reverseLunge(id: "balanced-extended-lunge", target: "左右8回"), pikePushup(id: "balanced-extended-pike", target: "6〜10回"), deadBug(id: "balanced-extended-deadbug", target: "左右10回"), hipBridge(id: "balanced-extended-bridge", target: "15回")]
        }
    }

    private static func kneePushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "ひざつきプッシュアップ", detail: "ひざを床につき、胸を手の間へ下ろす", purpose: "胸・腕", steps: ["手を肩幅より少し広く置き、ひざを床につく", "頭からひざまでを一直線にして、胸をゆっくり下ろす", "床を押して、腕を伸ばしきる手前まで戻る"], keyPoint: "腰を反らさず、胸で床を押す", target: target, systemImage: "figure.strengthtraining.functional")
    }

    private static func pushup(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "プッシュアップ", detail: "胸をゆっくり下げ、床を押して戻る", purpose: "胸・腕・体幹", steps: ["手を肩幅より少し広く置き、身体を一直線にする", "ひじを斜め後ろへ引きながら、胸をゆっくり下ろす", "床を強く押して、身体を一直線に戻す"], keyPoint: "腰を落とさず、胸を手の間へ運ぶ", target: target, systemImage: "figure.strengthtraining.functional")
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

    private static func deadBug(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "デッドバグ", detail: "腰を床につけたまま、手足をゆっくり動かす", purpose: "お腹・体幹", steps: ["仰向けでひざを90度に曲げ、腕を天井へ伸ばす", "腰を床に軽くつけたまま、片手と反対の脚を伸ばす", "戻してから反対側も行い、左右を交互に繰り返す"], keyPoint: "腰が浮く手前で止め、呼吸を止めない", target: target, systemImage: "figure.core.training")
    }

    private static func hipBridge(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "ヒップリフト", detail: "お尻を締めて、ゆっくり持ち上げる", purpose: "お尻・体幹", steps: ["仰向けでひざを立て、足を腰幅に置く", "かかとで床を押し、お尻をゆっくり持ち上げる", "お尻を締めたら、背中から順番にゆっくり下ろす"], keyPoint: "腰を反らず、お尻で持ち上げる", target: target, systemImage: "figure.core.training")
    }

    private static func sidePlank(id: String, target: String) -> Exercise {
        Exercise(id: id, name: "サイドプランク", detail: "身体を横向きにして、一直線を保つ", purpose: "脇腹・体幹", steps: ["横向きでひじを肩の真下につき、ひざを曲げる", "腰を持ち上げ、頭からひざまでを一直線にする", "呼吸を続けながら姿勢を保ち、反対側も行う"], keyPoint: "腰が落ちる前に終え、痛みがあれば中止する", target: target, systemImage: "figure.core.training")
    }
}
