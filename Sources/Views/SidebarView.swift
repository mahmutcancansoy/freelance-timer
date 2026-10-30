import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionEngine.self) private var engine
    @Binding var selectedPage: NavigationPage
    @State private var showingAddTag = false
    @State private var newTagName = ""
    @State private var newTagColor = Color.ftPrimary
    @State private var newTagRate = ""

    private let navItems: [(String, NavigationPage)] = [
        ("dashboard", .dashboard),
        ("folder_open", .projects),
        ("bar_chart", .reports),
        ("history", .history)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Navigation
            navigationSection

            Spacer().frame(height: 24)

            // Tags
            tagsSection

            Spacer()

            // Settings
            settingsButton
        }
        .padding(24)
        .background(Color.ftSurfaceDark.opacity(0.6))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(Color.white.opacity(0.05)),
            alignment: .trailing
        )
        .sheet(isPresented: $showingAddTag) {
            addTagSheet
        }
    }

    // MARK: – Navigation

    private var navigationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Localization.string(for: "menu", lang: engine.language).uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.gray)
                .tracking(1.5)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            ForEach(navItems, id: \.1) { (icon, page) in
                Button {
                    print("[Sidebar] Navigating to \(page.rawValue)")
                    selectedPage = page
                } label: {
                    navButton(icon: icon, title: Localization.string(for: page.rawValue.lowercased(), lang: engine.language), isSelected: selectedPage == page)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func navButton(icon: String, title: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemIconName(for: icon))
                .font(.system(size: 16))
                .frame(width: 20)

            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(isSelected ? Color.ftPrimary : .gray)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.ftPrimary.opacity(0.1) : .clear)
        )
        .contentShape(Rectangle())
    }

    // MARK: – Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Localization.string(for: "tags", lang: engine.language).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.gray)
                    .tracking(1.5)

                Spacer()

                Button(action: { showingAddTag = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            ForEach(tags) { tag in
                tagRow(tag: tag)
            }
        }
    }

    private func tagRow(tag: Tag) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tag.color)
                .frame(width: 8, height: 8)
                .shadow(color: tag.color.opacity(0.5), radius: 4)

            Text(tag.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray)

            Spacer()

            Text("\(tag.sessions.count)")
                .font(.system(size: 12))
                .foregroundStyle(Color.gray.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.clear)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button(Localization.string(for: "delete", lang: engine.language), role: .destructive) {
                modelContext.delete(tag)
            }
        }
    }

    // MARK: – Settings

    private var settingsButton: some View {
        Button {
            print("[Sidebar] Opening Settings")
            selectedPage = .settings
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .frame(width: 20)

                Text(Localization.string(for: "settings", lang: engine.language))
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(selectedPage == .settings ? Color.ftPrimary : .gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedPage == .settings ? Color.ftPrimary.opacity(0.1) : .clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: – Icon Mapping

    private func systemIconName(for materialIcon: String) -> String {
        switch materialIcon {
        case "dashboard": return "square.grid.2x2"
        case "folder_open": return "folder"
        case "calendar_month": return "calendar"
        case "bar_chart": return "chart.bar"
        case "history": return "clock.arrow.circlepath"
        default: return "circle"
        }
    }

    // MARK: – Add Tag Sheet

    private var addTagSheet: some View {
        VStack(spacing: 20) {
            Text(Localization.string(for: "create_tag", lang: engine.language))
                .font(.headline)

            TextField(Localization.string(for: "tag_name", lang: engine.language), text: $newTagName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Text(Localization.string(for: "hourly_rate", lang: engine.language) + " ($)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                TextField("0", text: $newTagRate)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }

            ColorPicker(Localization.string(for: "tag_color", lang: engine.language), selection: $newTagColor)

            HStack {
                Button(Localization.string(for: "cancel", lang: engine.language)) { showingAddTag = false }
                Spacer()
                Button(Localization.string(for: "create", lang: engine.language)) {
                    let hex = newTagColor.toHex() ?? "#2BEE6C"
                    let rate = Double(newTagRate) ?? 0.0
                    let tag = Tag(name: newTagName, colorHex: hex, hourlyRate: rate)
                    modelContext.insert(tag)
                    newTagName = ""
                    newTagRate = ""
                    showingAddTag = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTagName.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
