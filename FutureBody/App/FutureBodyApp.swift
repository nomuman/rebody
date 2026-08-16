import SwiftUI
import FirebaseCore

@main
struct FutureBodyApp: App {
    @StateObject private var store: WorkoutStore

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        _store = StateObject(wrappedValue: WorkoutStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(AppColor.accent)
        }
    }
}
