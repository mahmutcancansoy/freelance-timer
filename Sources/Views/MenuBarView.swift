import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(SessionEngine.self) private var engine
    @Environment(\.modelContext) private var modelContext

    private var analytics: AnalyticsService {
        AnalyticsService(modelContext: modelContext)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.ftPrimary)

                Text("FreelanceTimer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                statusBadge
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.1))

            // Active Session
            if engine.state != .idle {
                activeSessionSection
                    .padding(12)

                Divider()
                    .background(Color.white.opacity(0.1))
            }

            // Quick Controls
            controlsSection
                .padding(12)

            Divider()
                .background(Color.white.opacity(0.1))

            // Daily Stats
            dailyStatsSection
                .padding(12)

            Divider()
                .background(Color.white.opacity(0.1))

            // Open Main Window
            Button(action: openMainWindow) {
                HStack {
                    Image(systemName: "macwindow")
                        .font(.system(size: 12))
                    Text(Localization.string(for: "open_dashboard", lang: engine.language))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("⌘D")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                    Text(Localization.string(for: "quit", lang: engine.language))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("⌘Q")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                }
                .foregroundStyle(.red.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
        .frame(width: 300)
        .onAppear {
            engine.configure(modelContext: modelContext)
        }
    }

    // MARK: – Status Badge

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(engine.state == .idle ? Color.gray : (engine.state == .focusing ? Color.ftPrimary : Color.orange))
                .frame(width: 6, height: 6)

            Text(Localization.string(for: engine.state.localizationKey, lang: engine.language))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(engine.state == .idle ? .gray : .white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }

    // MARK: – Active Session

    private var activeSessionSection: some View {
        VStack(spacing: 8) {
            Text(engine.formattedTime)
                .font(.system(size: 36, weight: .black))
                .foregroundStyle(.white)
                .monospacedDigit()

            Text(engine.currentTaskName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray)
                .lineLimit(1)

            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.ftPrimary)
                        .frame(width: geometry.size.width * engine.progress)
                }
            }
            .frame(height: 4)
            .padding(.top, 4)
        }
    }

    // MARK: – Controls

    private var controlsSection: some View {
        HStack(spacing: 8) {
            if engine.state == .idle {
                Button(action: {
                    print("[MenuBar] Start Focus clicked")
                    engine.start()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                        Text(Localization.string(for: "start_focus", lang: engine.language))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.ftBackgroundDark)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.ftPrimary)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    print("[MenuBar] Toggle Pause/Resume clicked")
                    engine.togglePauseResume()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: engine.state == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 11))
                        Text(Localization.string(for: engine.state == .paused ? "resume" : "pause", lang: engine.language))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    print("[MenuBar] Stop clicked")
                    engine.stop()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                        Text(Localization.string(for: "stop", lang: engine.language))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: – Daily Stats

    private var dailyStatsSection: some View {
        HStack(spacing: 12) {
            miniStat(
                icon: "clock",
                value: analytics.formattedDailyFocusTime(language: engine.language),
                label: Localization.string(for: "today", lang: engine.language)
            )

            miniStat(
                icon: "checkmark.circle",
                value: "\(analytics.tasksCompletedToday())",
                label: Localization.string(for: "sessions", lang: engine.language)
            )

            miniStat(
                icon: "dollarsign.circle",
                value: String(format: "$%.0f", analytics.billableAmountToday()),
                label: Localization.string(for: "earned", lang: engine.language)
            )
        }
    }

    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.ftPrimary)

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Actions

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.title != "" || $0.contentView != nil }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
