import SwiftUI
import SwiftData

struct StatsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionEngine.self) private var engine
    @Query(filter: #Predicate<TimerSession> { !$0.isBreak }) private var allSessions: [TimerSession]

    private var analytics: AnalyticsService {
        AnalyticsService(modelContext: modelContext)
    }

    var body: some View {
        let weeklyGrowth = analytics.weeklyGrowthPercentage()
        HStack(spacing: 24) {
            // Total focused time
            statCard(
                icon: "timer",
                iconBg: Color.ftPrimary.opacity(0.2),
                iconColor: Color.ftPrimary,
                badge: String(format: "%+.0f%%", weeklyGrowth),
                badgeBg: (weeklyGrowth >= 0 ? Color.ftPrimary : Color.red).opacity(0.1),
                badgeColor: weeklyGrowth >= 0 ? Color.ftPrimary : Color.red,
                value: analytics.formattedWeeklyTotal(language: engine.language),
                label: Localization.string(for: "total_focused_time", lang: engine.language)
            )

            // Tasks completed
            statCard(
                icon: "checkmark.circle",
                iconBg: Color.purple.opacity(0.2),
                iconColor: Color.purple,
                badge: Localization.string(for: "today_stats", lang: engine.language),
                badgeBg: Color.clear,
                badgeColor: Color.gray,
                value: "\(analytics.tasksCompletedToday())",
                label: Localization.string(for: "tasks_completed", lang: engine.language)
            )

            // Billable amount
            statCard(
                icon: "dollarsign",
                iconBg: Color.blue.opacity(0.2),
                iconColor: Color.blue,
                badge: Localization.string(for: "today_stats", lang: engine.language),
                badgeBg: Color.blue.opacity(0.1),
                badgeColor: Color.blue,
                value: String(format: "$%.0f", analytics.billableAmountToday()),
                label: Localization.string(for: "billable_amount_stats", lang: engine.language)
            )
        }
    }

    private func statCard(
        icon: String,
        iconBg: Color,
        iconColor: Color,
        badge: String,
        badgeBg: Color,
        badgeColor: Color,
        value: String,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconBg)
                    )

                Spacer()

                Text(badge)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(badgeBg)
                    )
            }

            Spacer()

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
                .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .glassPanel(cornerRadius: 20)
    }
}
