import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    let projectName: String
    let sessions: [TimerSession]
    @Environment(SessionEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    // Group all sessions (including breaks) by date and sort chronologically
    private var timelineSessions: [(Date, [TimerSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private var totalWorkDuration: TimeInterval {
        sessions.filter { !$0.isBreak }.reduce(0) { $0 + $1.duration }
    }

    private var totalBreakDuration: TimeInterval {
        sessions.filter { $0.isBreak }.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            statsSection
                .padding(.horizontal, 24)
                .padding(.top, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(timelineSessions, id: \.0) { date, daySessions in
                        daySection(date: date, daySessions: daySessions)
                    }
                }
                .padding(24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.ftBackgroundDark.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(projectName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text(Localization.string(for: "project_details", lang: engine.language))
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
            .padding(.leading, 12)

            Spacer()
        }
        .padding(24)
        .background(Color.ftSurfaceDark.opacity(0.4))
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(
                title: Localization.string(for: "total_focus", lang: engine.language),
                value: formatDuration(totalWorkDuration),
                icon: "bolt.fill",
                color: Color.ftPrimary
            )

            statCard(
                title: Localization.string(for: "total_break", lang: engine.language),
                value: formatDuration(totalBreakDuration),
                icon: "cup.and.saucer.fill",
                color: .orange
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(cornerRadius: 16)
    }

    private func daySection(date: Date, daySessions: [TimerSession]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: engine.language.rawValue))))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.ftPrimary.opacity(0.8))
                .padding(.leading, 4)

            VStack(spacing: 1) {
                ForEach(daySessions.sorted(by: { $0.startTime > $1.startTime })) { session in
                    sessionRow(session)
                }
            }
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    private func sessionRow(_ session: TimerSession) -> some View {
        HStack {
            Circle()
                .fill(session.isBreak ? Color.orange : Color.ftPrimary)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.isBreak ? Localization.string(for: "resting", lang: engine.language) : (session.taskName.isEmpty ? Localization.string(for: "focus_session", lang: engine.language) : session.taskName))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)

                Text(session.startTime.formatted(.dateTime.hour().minute().locale(Locale(identifier: engine.language.rawValue))) + " - " + (session.endTime?.formatted(.dateTime.hour().minute().locale(Locale(identifier: engine.language.rawValue))) ?? Localization.string(for: "now", lang: engine.language)))
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            Spacer()

            Text(formatDuration(session.duration))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)

            if !session.isBreak && session.isBillable {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ftPrimary)
            }
        }
        .padding(16)
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
