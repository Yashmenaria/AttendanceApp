import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            AttendanceHistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar.badge.clock")
                }
                .tag(1)
            
            AIInsightsDashboardView()
                .tabItem {
                    Label("AI Insights", systemImage: "sparkles")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.primary)
    }
}

#Preview {
    MainTabView()
}
