import SwiftUI
import FirebaseCore

@main
struct FutureBodyApp: App {
    @UIApplicationDelegateAdaptor(FutureBodyAppDelegate.self) private var appDelegate
    @StateObject private var store: WorkoutStore

    init() {
        if FirebaseApp.app() == nil, FirebaseOptions.defaultOptions() != nil {
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
