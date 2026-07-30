import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CalendarHomeView()
            .tabItem { Label("日历", systemImage: "calendar") }

            NavigationStack {
                AnalysisView()
            }
            .tabItem { Label("分析", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }
}
