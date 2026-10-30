import SwiftUI
import SwiftData

struct RightPanelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: \TimerSession.startTime,
        order: .reverse
    ) private var recentSessions: [TimerSession]

    private var analytics: AnalyticsService {
        AnalyticsService(modelContext: modelContext)
    }

    @State private var showingGoalEdit = false
    @State private var hoveredDay: Int? = nil
    @Environment(SessionEngine.self) private var engine

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Daily Goal
            dailyGoalSection

            Spacer().frame(height: 24)

            // Session History
            sessionHistorySection

            Spacer()

            // Weekly Activity Chart
            weeklyActivitySection
        }
        .padding(24)
        .background(Color.ftSurfaceDark.opacity(0.6))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(Color.white.opacity(0.05)),
            alignment: .leading
        )
    }

    // MARK: – Daily Goal

    private var dailyGoalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(Localization.string(for: "daily_goal", lang: engine.language))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button(Localization.string(for: "edit", lang: engine.language)) { showingGoalEdit = true }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ftPrimary)
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingGoalEdit) {
                        VStack(spacing: 12) {
                            Text(Localization.string(for: "set_daily_goal", lang: engine.language))
                                .font(.headline)

                            HStack {
                                Slider(value: Binding(
                                    get: { Double(analytics.dailyGoal().targetSeconds / 60) },
                                    set: { engine.updateDailyGoal(minutes: Int($0)) }
                                ), in: 30...720, step: 30)

                                Text(Localization.duration(TimeInterval(analytics.dailyGoal().targetSeconds), lang: engine.language))
                                    .font(.system(size: 12, weight: .bold))
                                    .frame(width: 40)
                            }

                            Text(Localization.string(for: "target", lang: engine.language) + ": " + Localization.duration(TimeInterval(analytics.dailyGoal().targetSeconds), lang: engine.language))
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .frame(width: 250)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(analytics.formattedDailyFocusTime(language: engine.language))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("/ " + Localization.duration(TimeInterval(analytics.dailyGoal().targetSeconds), lang: engine.language))
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.ftPrimary)
                            .frame(width: geometry.size.width * analytics.dailyGoalProgress())
                            .shadow(color: Color.ftPrimary.opacity(0.5), radius: 10)
                    }
                }
                .frame(height: 8)

                Text(estimatedFinishText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.gray.opacity(0.6))
                    .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ftSurfaceDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
    }

    private var estimatedFinishText: String {
        let progress = analytics.dailyGoalProgress()
        if progress >= 1.0 {
            return "🎉 " + Localization.string(for: "goal_reached", lang: engine.language)
        }
        let remaining = (1.0 - progress) * Double(analytics.dailyGoal().targetSeconds)
        return "~" + Localization.duration(remaining, lang: engine.language) + " " + Localization.string(for: "remaining_to_goal", lang: engine.language)
    }

    // MARK: – Session History

    private var sessionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Localization.string(for: "session_history", lang: engine.language))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "ellipsis")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }

            if recentSessions.isEmpty {
                // Placeholder items
                ForEach(placeholderSessions, id: \.0) { item in
                    sessionRow(
                        icon: item.1,
                        iconColor: item.2,
                        title: item.3,
                        subtitle: item.4,
                        duration: item.5
                    )
                }
            } else {
                ForEach(Array(recentSessions.prefix(5))) { session in
                    sessionRow(
                        session: session,
                        icon: iconForSession(session),
                        iconColor: colorForSession(session),
                        title: session.isBreak ? Localization.string(for: "resting", lang: engine.language) : session.taskName,
                        subtitle: session.isBreak ? Localization.duration(session.duration, lang: engine.language) : (session.tags.first?.name ?? "No tag") + " • " + Localization.duration(session.duration, lang: engine.language),
                        duration: formatMinutes(session.duration)
                    )
                }
            }
        }
    }

    private var placeholderSessions: [(String, String, Color, String, String, String)] {
        [
            ("1", "paintbrush", Color.ftPrimary, "UI Polishing", "Design System • 45m", "45:00"),
            ("2", "chevron.left.forwardslash.chevron.right", Color.blue, "API Integration", "Development • 1h 20m", "80:00"),
            ("3", "envelope", Color.purple, "Client Emails", "Admin • 30m", "30:00")
        ]
    }

    private func sessionRow(
        session: TimerSession? = nil, // Optional to support placeholders
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        duration: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Text(duration)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                )

            if let session = session {
                Button(action: { engine.deleteSession(session) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(.red.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }

    // MARK: – Weekly Activity

    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.bottom, 8)

            Text(Localization.string(for: "weekly_activity", lang: engine.language))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            weeklyBarChart

            weekDayLabels
        }
    }

    private var weeklyBarChart: some View {
        let activity = analytics.weeklyActivity()
        let maxVal = max(activity.max() ?? 1, 1)
        let dayIndex = (Calendar.current.component(.weekday, from: .now) + 5) % 7

        return HStack(alignment: .bottom, spacing: 4) {
            ForEach(0..<7, id: \.self) { i in
                let height = activity.count > i ? activity[i] / maxVal : 0
                let isToday = i == dayIndex
                let isHovered = hoveredDay == i

                VStack {
                    if isHovered {
                        Text(Localization.duration(activity[i], lang: engine.language))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.ftSurfaceDark)
                            .cornerRadius(4)
                            .offset(y: -5)
                    }

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isToday ? Color.ftPrimary : (isHovered ? Color.white.opacity(0.15) : Color.white.opacity(0.05)))
                        .frame(maxWidth: .infinity)
                        .frame(height: max(CGFloat(height) * 128, 4))
                        .shadow(
                            color: isToday ? Color.ftPrimary.opacity(0.3) : .clear,
                            radius: 10
                        )
                }
                .onHover { over in
                    withAnimation(.spring(response: 0.3)) {
                        hoveredDay = over ? i : nil
                    }
                }
            }
        }
        .frame(height: 140) // Increased height for tooltips
    }

    private var weekDayLabels: some View {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: engine.language.rawValue)
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let labels = Array(symbols.dropFirst()) + [symbols[0]]
        let dayIndex = (Calendar.current.component(.weekday, from: .now) + 5) % 7

        return HStack {
            ForEach(0..<7, id: \.self) { i in
                Text(labels[i])
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(i == dayIndex ? Color.ftPrimary : .gray)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: – Helpers

    private func iconForSession(_ session: TimerSession) -> String {
        if session.isBreak {
            return "cup.and.saucer"
        }
        if let tag = session.tags.first {
            switch tag.name.lowercased() {
            case let n where n.contains("design"): return "paintbrush"
            case let n where n.contains("dev"): return "chevron.left.forwardslash.chevron.right"
            case let n where n.contains("meeting"): return "video"
            case let n where n.contains("admin"): return "envelope"
            default: return "circle"
            }
        }
        return "clock"
    }

    private func colorForSession(_ session: TimerSession) -> Color {
        if session.isBreak {
            return .orange
        }
        return session.tags.first?.color ?? Color.ftPrimary
    }

    private func formatMinutes(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
