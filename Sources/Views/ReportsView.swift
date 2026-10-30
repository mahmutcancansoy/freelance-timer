import SwiftUI
import SwiftData

struct ReportsView: View {
    @Query private var sessions: [TimerSession]
    @Environment(SessionEngine.self) private var engine

    private var tagDistribution: [String: TimeInterval] {
        var distribution: [String: TimeInterval] = [:]
        for session in sessions.filter({ !$0.isBreak }) {
            for tag in session.tags {
                distribution[tag.name, default: 0] += session.duration
            }
        }
        return distribution
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection

            ScrollView {
                VStack(spacing: 24) {
                    tagDistributionSection

                    billableSection
                }
            }
        }
        .padding(24)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string(for: "reports", lang: engine.language))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(Localization.string(for: "analyze_productivity", lang: engine.language))
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
    }

    private var tagDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localization.string(for: "time_by_tag", lang: engine.language))
                .font(.headline)
                .foregroundStyle(.white)

            if tagDistribution.isEmpty {
                Text(Localization.string(for: "no_data_to_report", lang: engine.language))
                    .foregroundStyle(.gray)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(tagDistribution.keys.sorted(), id: \.self) { tagName in
                        let duration = tagDistribution[tagName] ?? 0
                        HStack {
                            Text(tagName)
                            Spacer()
                            Text(formatDuration(duration))
                                .bold()
                                .foregroundStyle(Color.ftPrimary)
                        }
                        .padding(12)
                        .glassPanel(cornerRadius: 12)
                    }
                }
            }
        }
    }

    private var billableSection: some View {
        let totalBillable = sessions.reduce(0) { $0 + $1.billableAmount }

        return VStack(alignment: .leading, spacing: 16) {
            Text(Localization.string(for: "billable_summary", lang: engine.language))
                .font(.headline)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("\(String(format: "$%.2f", totalBillable))")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Color.ftPrimary)

                Text(Localization.string(for: "total_earned_to_date", lang: engine.language))
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassPanel(cornerRadius: 16)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
