import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("今日", systemImage: "sun.max")
            }

            NavigationStack {
                ProgressViewScreen()
            }
            .tabItem {
                Label("記録", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                TeamView()
            }
            .tabItem {
                Label("チーム", systemImage: "person.3")
            }
        }
    }
}
