import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Query private var sessions: [TimerSession]
    @Query private var allTags: [Tag]
    @Environment(SessionEngine.self) private var engine
    @State private var selectedProject: String? = nil

    // Group projects by their first tag, or "No Tag"
    private var tagGroups: [String: [(String, [TimerSession])]] {
        let projects = Dictionary(grouping: sessions.filter { !$0.isBreak }) { $0.taskName }

        var groups: [String: [(String, [TimerSession])]] = [:]

        for (name, projectSessions) in projects {
            let tagName = projectSessions.first?.tags.first?.name ?? "Other"
            if groups[tagName] == nil {
                groups[tagName] = []
            }
            groups[tagName]?.append((name, projectSessions))
        }

        return groups
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if tagGroups.isEmpty {
                        emptyState
                    } else {
                        ForEach(tagGroups.keys.sorted(), id: \.self) { tagName in
                            tagSection(name: tagName, projects: tagGroups[tagName] ?? [])
                        }
                    }
                }
            }
        }
        .padding(24)
        .sheet(item: Binding(
            get: { selectedProject.map { ProjectIdentifiable(id: $0) } },
            set: { selectedProject = $0?.id }
        )) { project in
            ProjectDetailView(
                projectName: project.id,
                sessions: sessions.filter { $0.taskName == project.id }
            )
            .environment(engine)
        }
    }

    struct ProjectIdentifiable: Identifiable {
        let id: String
    }

    private func tagSection(name: String, projects: [(String, [TimerSession])]) -> some View {
        let totalTagDuration = projects.flatMap { $0.1 }.reduce(0) { $0 + $1.duration }
        let tagColor = projects.first?.1.first?.tags.first?.color ?? .gray

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(tagColor)
                    .frame(width: 8, height: 8)

                Text(name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Text(formatDuration(totalTagDuration))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(projects, id: \.0) { projectName, projectSessions in
                    projectCard(name: projectName, sessions: projectSessions)
                        .onTapGesture {
                            selectedProject = projectName
                        }
                }
            }
        }
    }

    private func projectCard(name: String, sessions: [TimerSession]) -> some View {
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let totalEarned = sessions.reduce(0) { $0 + $1.billableAmount }

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.gray)
            }

            HStack {
                Text(formatDuration(totalDuration))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.ftPrimary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Localization.string(for: "earned", lang: engine.language))
                        .font(.system(size: 9))
                        .foregroundStyle(.gray)
                    Text(String(format: "$%.2f", totalEarned))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .glassPanel(cornerRadius: 16)
        .contentShape(Rectangle())
    }

    private var headerSection: some View {
        let projectCount = tagGroups.values.flatMap { $0 }.count
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string(for: "projects", lang: engine.language))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("\(projectCount) " + Localization.string(for: "active_projects_tracked", lang: engine.language))
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.minus")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            Text(Localization.string(for: "no_projects_yet", lang: engine.language))
                .font(.headline)
            Text(Localization.string(for: "start_focus_to_see", lang: engine.language))
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
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
