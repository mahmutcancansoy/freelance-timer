import SwiftUI
import SwiftData

@main
struct FreelanceTimerApp: App {

    @State private var engine = SessionEngine()

    init() {
        if let iconURL = Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
           let iconImage = NSImage(contentsOf: iconURL) {
            NSApplication.shared.applicationIconImage = iconImage
        }
    }

    var body: some Scene {
        // Main Window
        WindowGroup {
            ContentView()
                .environment(engine)
                .frame(minWidth: 1200, minHeight: 750)
        }
        .modelContainer(for: [TimerSession.self, Tag.self, DailyGoal.self])
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1440, height: 900)

        // MenuBar Extra
        MenuBarExtra {
            MenuBarView()
                .environment(engine)
                .modelContainer(for: [TimerSession.self, Tag.self, DailyGoal.self])
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                if engine.state != .idle {
                    Text(engine.formattedTime)
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
