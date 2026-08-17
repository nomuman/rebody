import XCTest
@testable import FutureBody

@MainActor
final class WorkoutStoreTests: XCTestCase {
    func testLowEnergyRecommendsRescuePlan() {
        let store = WorkoutStore(userDefaults: testDefaults())
        store.dailyState = DailyState(availableMinutes: 10, energy: .low, bodyStatus: .good, interruptionRisk: true)

        XCTAssertEqual(store.recommendedPlan.type, .rescue)
    }

    func testPainRecommendsRescuePlan() {
        let store = WorkoutStore(userDefaults: testDefaults())
        store.dailyState = DailyState(availableMinutes: 15, energy: .high, bodyStatus: .pain, interruptionRisk: false)

        XCTAssertEqual(store.recommendedPlan.type, .rescue)
        XCTAssertTrue(store.shouldRestToday)
    }

    func testInterruptionRiskDoesNotReplaceFifteenMinuteChoice() {
        let store = WorkoutStore(userDefaults: testDefaults())
        store.dailyState = DailyState(availableMinutes: 15, energy: .high, bodyStatus: .good, interruptionRisk: true)

        XCTAssertEqual(store.recommendedPlan.type, .extended)
    }

    func testHighEnergyAndTimeRecommendsExtendedPlan() {
        let store = WorkoutStore(userDefaults: testDefaults())
        store.dailyState = DailyState(availableMinutes: 15, energy: .high, bodyStatus: .good, interruptionRisk: false)

        XCTAssertEqual(store.recommendedPlan.type, .extended)
        XCTAssertEqual(store.recommendedPlan.type.durationLabel, "15分以上")
        XCTAssertEqual(store.recommendedPlan.rounds, 3)
    }

    func testTenMinutePlanUsesTwoRounds() {
        let store = WorkoutStore(userDefaults: testDefaults())
        store.dailyState = DailyState(availableMinutes: 10, energy: .normal, bodyStatus: .good, interruptionRisk: true)

        XCTAssertEqual(store.recommendedPlan.type, .standard)
        XCTAssertEqual(store.recommendedPlan.type.durationLabel, "10分")
        XCTAssertEqual(store.recommendedPlan.rounds, 2)
        XCTAssertTrue(store.recommendedPlan.format.contains("2周"))
    }

    func testWorkoutVariationsUseDifferentExerciseRoutes() {
        let first = WorkoutCatalog.plan(for: .appearance, type: .standard, variation: 0)
        let second = WorkoutCatalog.plan(for: .appearance, type: .standard, variation: 1)

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertNotEqual(first.exercises.map(\.name), second.exercises.map(\.name))
    }

    func testAppearanceFocusRecommendsAppearancePlan() {
        let store = WorkoutStore(userDefaults: testDefaults())
        store.dailyState = DailyState(availableMinutes: 10, energy: .normal, bodyStatus: .good, interruptionRisk: false, focus: .appearance)

        XCTAssertEqual(store.recommendedPlan.focus, .appearance)
        XCTAssertTrue(store.recommendedPlan.title.contains("お腹"))
        XCTAssertTrue(store.recommendedPlan.exercises.contains { $0.purpose.contains("お腹") })
    }

    func testUpperBodyFocusRecommendsChestAndArmPlan() {
        let store = WorkoutStore(userDefaults: testDefaults())
        store.dailyState = DailyState(availableMinutes: 10, energy: .normal, bodyStatus: .good, interruptionRisk: false, focus: .upperBody)

        XCTAssertEqual(store.recommendedPlan.focus, .upperBody)
        XCTAssertTrue(store.recommendedPlan.title.contains("胸と腕"))
        XCTAssertTrue(store.recommendedPlan.exercises.contains { $0.purpose.contains("腕") })
    }

    func testOldDailyStateWithoutFocusDefaultsToAppearance() throws {
        let data = #"{"availableMinutes":10,"energy":"normal","bodyStatus":"good","interruptionRisk":true}"#.data(using: .utf8)!

        let state = try JSONDecoder().decode(DailyState.self, from: data)

        XCTAssertEqual(state.focus, .appearance)
    }

    func testCompletionIsPersisted() {
        let defaults = testDefaults()
        let firstStore = WorkoutStore(userDefaults: defaults)
        firstStore.complete(plan: WorkoutCatalog.rescue)

        let secondStore = WorkoutStore(userDefaults: defaults)

        XCTAssertEqual(secondStore.totalCompleted, 1)
        XCTAssertEqual(secondStore.records.first?.sessionType, .rescue)
    }

    func testLocalCoachPrioritizesRestWhenPainIsSelected() {
        let state = DailyState(availableMinutes: 15, energy: .high, bodyStatus: .pain, interruptionRisk: false)
        let message = LocalCoachMessage.make(state: state, plan: WorkoutCatalog.standard)

        XCTAssertTrue(message.contains("休む"))
    }

    func testLocalCoachKeepsTheSmallestStepOnBusyLowEnergyDays() {
        let state = DailyState(availableMinutes: 10, energy: .low, bodyStatus: .good, interruptionRisk: true)
        let message = LocalCoachMessage.make(state: state, plan: WorkoutCatalog.rescue)

        XCTAssertTrue(message.contains("2分"))
    }

    func testMergingRemoteAndLocalDuplicateRecordsKeepsOneRecord() {
        let id = UUID()
        let remoteRecord = WorkoutRecord(
            id: id,
            planID: "remote-plan",
            sessionType: .standard,
            completedAt: Date(timeIntervalSince1970: 100),
            durationMinutes: 10
        )
        let localRecord = WorkoutRecord(
            id: id,
            planID: "local-plan",
            sessionType: .rescue,
            completedAt: Date(timeIntervalSince1970: 200),
            durationMinutes: 2
        )

        let merged = mergeWorkoutRecords(remoteRecords: [remoteRecord], localRecords: [localRecord])

        XCTAssertEqual(merged.count, 1)
        XCTAssertEqual(merged.first?.planID, "local-plan")
    }

    private func testDefaults() -> UserDefaults {
        let suiteName = "FutureBodyTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }
}
