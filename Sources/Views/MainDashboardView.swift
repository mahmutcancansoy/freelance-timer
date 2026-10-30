import SwiftUI
import SwiftData

struct MainDashboardView: View {
    @Environment(SessionEngine.self) private var engine

    @State private var isEditingTask = false
    @State private var newTaskName = ""
    @State private var showingNotifications = false
    @State private var customDuration = 25
    @State private var customBreakDuration = 10
    @State private var showingCustomBreakPopover = false
    @State private var pulseEffect = false
    @State private var pendingTags: [Tag] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(Color.ftPrimary.opacity(0.05))
                .frame(width: 600, height: 600)
                .blur(radius: 120)

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.bottom, 12)

                Spacer()

                // Timer area
                TimerView()

                if engine.state == .idle {
                    breakPresetsSection
                        .padding(.top, 24)
                }

                Spacer()

                // Stats grid
                StatsGridView()
                    .padding(.bottom, 24)
            }
            .padding(24)
            .animation(.spring(), value: isEditingTask)
        }
    }

    @Query(sort: \Tag.name) private var availableTags: [Tag]

    private var taskEditSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField(Localization.string(for: "placeholder_task", lang: engine.language), text: $newTaskName)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .focused($isFocused)
                    .onSubmit {
                        print("[MainDashboard] Submitted via Return key")
                        saveTask()
                    }
                    .onAppear {
                        // Extra insurance for focus
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isFocused = true
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1)) // Increased opacity for better visibility
                    .cornerRadius(8)
                    .overlay(
                        HStack {
                            Spacer()
                            if !newTaskName.isEmpty {
                                Button(action: { newTaskName = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.gray)
                                        .padding(.trailing, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    )

                Button(Localization.string(for: "save", lang: engine.language)) {
                    saveTask()
                }
                .buttonStyle(.borderedProminent)

                Button(Localization.string(for: "cancel", lang: engine.language)) {
                    print("[MainDashboard] Cancelled task edit")
                    isEditingTask = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.gray)
            }

            Text(Localization.string(for: "select_tags", lang: engine.language))
                .font(.caption)
                .foregroundStyle(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(availableTags) { tag in
                        Button(action: {
                            print("[MainDashboard] Toggle tag: \(tag.name)")
                            if pendingTags.contains(where: { $0.id == tag.id }) {
                                pendingTags.removeAll { $0.id == tag.id }
                            } else {
                                pendingTags.append(tag)
                            }
                        }) {
                            Text(tag.name)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(pendingTags.contains(where: { $0.id == tag.id }) ? tag.color : Color.white.opacity(0.1))
                                )
                                .foregroundStyle(pendingTags.contains(where: { $0.id == tag.id }) ? .black : .white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.1))

            HStack {
                Text(Localization.string(for: "duration", lang: engine.language))
                    .font(.caption)
                    .foregroundStyle(.gray)

                Spacer()

                HStack(spacing: 8) {
                    TextField("", value: $customDuration, format: .number)
                        .textFieldStyle(.plain)
                        .frame(width: 50)
                        .multilineTextAlignment(.center)
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)

                    Text(Localization.string(for: "min", lang: engine.language))

                    Stepper("", value: $customDuration, in: 1...480, step: 5)
                        .labelsHidden()
                }
            }

            Divider().background(Color.white.opacity(0.1))

            Text(Localization.string(for: "recent_tasks", lang: engine.language))
                .font(.caption)
                .foregroundStyle(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(engine.recentUniqueTasks()) { session in
                        Button(action: {
                            newTaskName = session.taskName
                            pendingTags = session.tags
                            customDuration = Int(session.duration / 60)

                            // Visual feedback
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                pulseEffect = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation { pulseEffect = false }
                            }

                            print("[MainDashboard] Applied preset: \(session.taskName) with tags: \(session.tags.map { $0.name }) and duration: \(customDuration)")
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.taskName)
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)

                                HStack {
                                    ForEach(session.tags.prefix(2)) { tag in
                                        Circle()
                                            .fill(tag.color)
                                            .frame(width: 6, height: 6)
                                    }
                                    Spacer()
                                    Text(Localization.duration(session.duration, lang: engine.language))
                                        .font(.system(size: 9))
                                        .foregroundStyle(.gray)
                                }
                            }
                            .padding(8)
                            .frame(width: 120)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .glassPanel(cornerRadius: 12)
        .scaleEffect(pulseEffect ? 1.02 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(pulseEffect ? Color.ftPrimary : (isFocused ? Color.ftPrimary.opacity(0.5) : Color.clear), lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .animation(.spring(), value: pulseEffect)
    }

    // MARK: – Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string(for: "focus_session", lang: engine.language))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(formattedDate)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }

            Spacer()

            HStack(spacing: 16) {
                // Notification button
                Button(action: {
                    engine.clearNotifications()
                    showingNotifications = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassPanel(cornerRadius: 20)

                        if engine.unreadNotificationsCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: -2, y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingNotifications) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Localization.string(for: "recent_activity", lang: engine.language))
                            .font(.headline)

                        if engine.recentLogs.isEmpty {
                            Text(Localization.string(for: "no_recent_activity", lang: engine.language))
                                .font(.caption)
                                .foregroundStyle(.gray)
                        } else {
                            ForEach(engine.recentLogs, id: \.self) { log in
                                Text(log)
                                    .font(.caption)
                                    .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .frame(width: 250)
                }

                // New Task button
                Button(action: {
                    print("[MainDashboard] New Task clicked - Resetting state")
                    newTaskName = ""
                    pendingTags = []
                    customDuration = 25
                    isEditingTask = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text(Localization.string(for: "new_task", lang: engine.language))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(Color.ftBackgroundDark)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.ftPrimary)
                    )
                    .shadow(color: Color.ftPrimary.opacity(0.3), radius: 15)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isEditingTask) {
                    taskEditSection
                        .frame(width: 500)
                        .padding(24)
                        .background(Color.ftBackgroundDark.ignoresSafeArea())
                }
            }
        }
    }

    private var formattedDate: String {
        let locale = Locale(identifier: engine.language.rawValue)
        return Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day().locale(locale))
    }

    private var breakPresetsSection: some View {
        VStack(spacing: 12) {
            Text(Localization.string(for: "add_break", lang: engine.language))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.gray)
                .tracking(1)

            HStack(spacing: 12) {
                breakButton(label: "5m", mins: 5)
                breakButton(label: "10m", mins: 10)
                breakButton(label: "15m", mins: 15)

                // Custom break button with Popover
                Button(action: { showingCustomBreakPopover = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundStyle(Color.orange)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingCustomBreakPopover) {
                    VStack(spacing: 16) {
                        Text(Localization.string(for: "duration", lang: engine.language))
                            .font(.headline)

                        HStack {
                            TextField("", value: $customBreakDuration, format: .number)
                                .textFieldStyle(.plain)
                                .frame(width: 60)
                                .multilineTextAlignment(.center)
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)

                            Text(Localization.string(for: "min", lang: engine.language))
                        }

                        Button(action: {
                            showingCustomBreakPopover = false
                            engine.startBreak(minutes: customBreakDuration)
                        }) {
                            Text(Localization.string(for: "start_break", lang: engine.language))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.ftBackgroundDark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .frame(width: 180)
                }

                breakButton(label: Localization.string(for: "untimed", lang: engine.language), mins: nil)
            }
        }
    }

    private func breakButton(label: String, mins: Int?) -> some View {
        Button(action: {
            engine.startBreak(minutes: mins)
        }) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
                .foregroundStyle(Color.orange)
        }
        .buttonStyle(.plain)
    }

    private func saveTask() {
        print("[MainDashboard] Saving task: \(newTaskName)")
        engine.updateCurrentSession(
            taskName: newTaskName,
            tags: pendingTags,
            durationMinutes: customDuration
        )
        isEditingTask = false
        isFocused = false
    }
}
