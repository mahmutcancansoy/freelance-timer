import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(SessionEngine.self) private var engine
    @Query(sort: \TimerSession.startTime, order: .reverse) private var allSessions: [TimerSession]

    @State private var filter: HistoryFilter = .all
    @State private var sessionToDelete: TimerSession?

    enum HistoryFilter: String, CaseIterable {
        case all = "all"
        case sessions = "sessions_only"
        case breaks = "breaks_only"
    }

    var filteredSessions: [TimerSession] {
        switch filter {
        case .all: return allSessions
        case .sessions: return allSessions.filter { !$0.isBreak }
        case .breaks: return allSessions.filter { $0.isBreak }
        }
    }

    var groupedSessions: [(Date, [TimerSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection

            filterPicker

            if filteredSessions.isEmpty {
                emptyState
            } else {
                sessionList
            }
        }
        .padding(24)
        .alert(Localization.string(for: "confirm_delete", lang: engine.language), isPresented: .init(get: { sessionToDelete != nil }, set: { if !$0 { sessionToDelete = nil } })) {
            Button(Localization.string(for: "delete", lang: engine.language), role: .destructive) {
                if let session = sessionToDelete {
                    engine.deleteSession(session)
                }
            }
            Button(Localization.string(for: "cancel", lang: engine.language), role: .cancel) {}
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string(for: "history", lang: engine.language))
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Text("\(filteredSessions.count) \(Localization.string(for: "entries_found", lang: engine.language))")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
        }
    }

    private var filterPicker: some View {
        Picker("", selection: $filter) {
            ForEach(HistoryFilter.allCases, id: \.self) { f in
                Text(Localization.string(for: f.rawValue, lang: engine.language)).tag(f)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 300)
    }

    private var sessionList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(groupedSessions, id: \.0) { date, sessions in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(formatHeaderDate(date))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.ftPrimary.opacity(0.8))
                            .padding(.leading, 4)

                        VStack(spacing: 8) {
                            ForEach(sessions) { session in
                                sessionRow(session)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func sessionRow(_ session: TimerSession) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(session.isBreak ? Color.orange.opacity(0.1) : Color.ftPrimary.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: session.isBreak ? "cup.and.saucer.fill" : "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(session.isBreak ? Color.orange : Color.ftPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.isBreak ? Localization.string(for: "resting", lang: engine.language) : session.taskName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)

                Text(session.startTime.formatted(.dateTime.hour().minute().locale(Locale(identifier: engine.language.rawValue))) + " - " + (session.endTime?.formatted(.dateTime.hour().minute().locale(Locale(identifier: engine.language.rawValue))) ?? Localization.string(for: "now", lang: engine.language)))
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            Spacer()

            // Duration & Tags
            HStack(spacing: 12) {
                if !session.isBreak {
                    HStack(spacing: 4) {
                        ForEach(session.tags.prefix(3)) { tag in
                            Circle()
                                .fill(tag.color)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Text(Localization.duration(session.duration, lang: engine.language))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 60, alignment: .trailing)

                Button(action: { sessionToDelete = session }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.red.opacity(0.6))
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassPanel(cornerRadius: 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.gray.opacity(0.5))
            Text(Localization.string(for: "no_history", lang: engine.language))
                .font(.headline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private func formatHeaderDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Localization.string(for: "today", lang: engine.language)
        } else if calendar.isDateInYesterday(date) {
            return Localization.string(for: "yesterday", lang: engine.language)
        } else {
            return date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: engine.language.rawValue)))
        }
    }
}
