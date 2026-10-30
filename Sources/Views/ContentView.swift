import SwiftUI
import SwiftData

enum NavigationPage: String, CaseIterable {
    case dashboard = "Dashboard"
    case projects = "Projects"
    case reports = "Reports"
    case history = "History"
    case settings = "Settings"
}

struct ContentView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext
    @State private var selectedPage: NavigationPage = .dashboard

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedPage: $selectedPage)
                .frame(width: 256)

            mainArea

            RightPanelView()
                .frame(width: 320)
        }
        .appBackground()
        .preferredColorScheme(.dark)
        .onAppear {
            engine.configure(modelContext: modelContext)
            // Seed default tags
            let tagging = TaggingService(modelContext: modelContext)
            tagging.seedDefaultTags()
            // Request notification permissions
            NotificationService().requestPermission()
        }
    }

    @ViewBuilder
    private var mainArea: some View {
        switch selectedPage {
        case .dashboard:
            MainDashboardView()
        case .projects:
            ProjectsView()
        case .reports:
            ReportsView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}
