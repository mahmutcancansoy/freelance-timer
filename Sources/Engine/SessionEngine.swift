import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class SessionEngine {

    // MARK: – State

    enum TimerState: String, Equatable {
        case idle = "Ready"
        case focusing = "Focusing"
        case resting = "Resting"
        case waitingForRest = "WaitingForRest"
        case paused = "Paused"

        var localizationKey: String {
            switch self {
            case .idle: "idle"
            case .focusing: "focusing"
            case .resting: "resting"
            case .waitingForRest: "waitingforrest"
            case .paused: "paused"
            }
        }
    }

    private(set) var state: TimerState = .idle
    private(set) var remainingSeconds: Int = 25 * 60
    private(set) var totalSeconds: Int = 25 * 60
    private(set) var completedPomodoros: Int = 0

    var currentTaskName: String = ""
    var isBillable: Bool = true
    var hourlyRate: Double = 75.0
    var selectedTags: [Tag] = []
    var language: Language = .preferred {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "preferredLanguage") }
    }

    // MARK: – Notifications State

    private(set) var unreadNotificationsCount: Int = 0
    private(set) var recentLogs: [String] = []

    // MARK: – Configuration

    var focusDurationMinutes: Int = 25 {
        didSet {
            focusDurationMinutes = min(max(focusDurationMinutes, 1), 480)
            if state == .idle { totalSeconds = focusDurationMinutes * 60; remainingSeconds = totalSeconds }
        }
    }
    var shortBreakMinutes: Int = 5 {
        didSet { shortBreakMinutes = min(max(shortBreakMinutes, 1), 180) }
    }
    var longBreakMinutes: Int = 15 {
        didSet { longBreakMinutes = min(max(longBreakMinutes, 1), 240) }
    }
    var pomodorosBeforeLongBreak: Int = 4 {
        didSet { pomodorosBeforeLongBreak = min(max(pomodorosBeforeLongBreak, 1), 12) }
    }

    // MARK: – Progress

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(totalSeconds))
    }

    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var stateBeforePause: TimerState = .idle

    // MARK: – Private

    private var timer: DispatchSourceTimer?
    private var modelContext: ModelContext?
    private var sessionStartTime: Date?
    private var pauseStartedAt: Date?
    private var accumulatedPause: TimeInterval = 0
    private var isUntimedBreak = false
    private let notificationService = NotificationService()

    // MARK: – Init

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext

        self.language = .preferred
    }

    // MARK: – Controls

    func start(customDurationMinutes: Int? = nil) {
        guard state == .idle else { return }
        isUntimedBreak = false
        totalSeconds = max(1, customDurationMinutes ?? focusDurationMinutes) * 60
        remainingSeconds = totalSeconds
        state = .focusing
        sessionStartTime = .now
        startTimer()
    }

    func pause() {
        guard state == .focusing || state == .resting else { return }
        stateBeforePause = state
        state = .paused
        pauseStartedAt = .now
        stopTimer()
    }

    func resume() {
        guard state == .paused else { return }
        if let pauseStartedAt {
            accumulatedPause += Date.now.timeIntervalSince(pauseStartedAt)
        }
        self.pauseStartedAt = nil
        state = stateBeforePause
        startTimer()
    }

    func togglePauseResume() {
        if state == .paused {
            resume()
        } else if state == .focusing || state == .resting {
            pause()
        } else {
            start()
        }
    }

    func stop() {
        if state == .focusing, let startTime = sessionStartTime {
            persistSession(startTime: startTime, isBreak: false, endTime: .now, pausedDuration: accumulatedPause)
        } else if state == .resting || state == .waitingForRest, let startTime = sessionStartTime {
            persistSession(startTime: startTime, isBreak: true, endTime: .now, pausedDuration: accumulatedPause)
        } else if state == .paused, let startTime = sessionStartTime {
            let isBreak = stateBeforePause == .resting
            let endTime = pauseStartedAt ?? .now
            persistSession(startTime: startTime, isBreak: isBreak, endTime: endTime, pausedDuration: accumulatedPause)
        }

        resetToIdle()
    }

    func startBreak(minutes: Int?) {
        guard state == .idle else { return }
        isUntimedBreak = minutes == nil
        let mins = max(1, minutes ?? 0)
        totalSeconds = isUntimedBreak ? 0 : mins * 60
        remainingSeconds = totalSeconds
        state = .resting
        sessionStartTime = .now
        startTimer()
    }

    func reset() {
        stopTimer()
        let phase: TimerState = state == .paused ? stateBeforePause : state
        if phase == .idle || phase == .focusing {
            totalSeconds = focusDurationMinutes * 60
            isUntimedBreak = false
        } else if phase == .waitingForRest {
            let interval = max(1, pomodorosBeforeLongBreak)
            let breakMinutes = (completedPomodoros % interval == 0 && completedPomodoros > 0) ? longBreakMinutes : shortBreakMinutes
            totalSeconds = max(1, breakMinutes) * 60
            isUntimedBreak = false
        } else if isUntimedBreak {
            totalSeconds = 0
        } else {
            let interval = max(1, pomodorosBeforeLongBreak)
            let breakMinutes = (completedPomodoros % interval == 0 && completedPomodoros > 0) ? longBreakMinutes : shortBreakMinutes
            totalSeconds = breakMinutes * 60
        }
        remainingSeconds = totalSeconds
        if phase == .focusing || phase == .resting {
            sessionStartTime = .now
            pauseStartedAt = state == .paused ? .now : nil
            accumulatedPause = 0
        }
        if state == .focusing || state == .resting {
            startTimer()
        }
    }

    func updateDailyGoal(minutes: Int) {
        guard let context = modelContext else { return }
        let date = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<DailyGoal>(predicate: #Predicate<DailyGoal> { $0.date == date })

        if let existing = try? context.fetch(descriptor).first {
            existing.targetSeconds = minutes * 60
        } else {
            let newGoal = DailyGoal(date: date, targetSeconds: minutes * 60)
            context.insert(newGoal)
        }
        try? context.save()
    }

    func clearNotifications() {
        unreadNotificationsCount = 0
    }

    func deleteSession(_ session: TimerSession) {
        guard let context = modelContext else { return }
        context.delete(session)
        try? context.save()
        addLog(Localization.string(for: "session_deleted", lang: language))
    }

    private func addLog(_ message: String) {
        recentLogs.insert("\(Date().formatted(date: .omitted, time: .shortened)): \(message)", at: 0)
        if recentLogs.count > 10 { recentLogs.removeLast() }
        unreadNotificationsCount += 1
    }

    func skip() {
        stopTimer()
        let phase = state == .paused ? stateBeforePause : state
        if phase == .focusing {
            if let startTime = sessionStartTime {
                let endTime = state == .paused ? (pauseStartedAt ?? .now) : .now
                persistSession(startTime: startTime, isBreak: false, endTime: endTime, pausedDuration: accumulatedPause)
            }
            completedPomodoros += 1
            let interval = max(1, pomodorosBeforeLongBreak)
            let breakMinutes = completedPomodoros % interval == 0 ? longBreakMinutes : shortBreakMinutes
            totalSeconds = max(1, breakMinutes) * 60
            remainingSeconds = totalSeconds
            state = .waitingForRest
            sessionStartTime = nil
            pauseStartedAt = nil
            accumulatedPause = 0
        } else if phase == .waitingForRest || phase == .resting {
            if phase == .resting, let startTime = sessionStartTime {
                let endTime = state == .paused ? (pauseStartedAt ?? .now) : .now
                persistSession(startTime: startTime, isBreak: true, endTime: endTime, pausedDuration: accumulatedPause)
            }
            resetToIdle()
        }
    }

    // MARK: – Timer Logic

    private func startTimer() {
        stopTimer()
        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(deadline: .now() + 1, repeating: 1.0, leeway: .milliseconds(100))
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        source.resume()
        timer = source
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        if isUntimedBreak {
            remainingSeconds += 1
            return
        }
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            handleTimerComplete()
        }
    }

    private func handleTimerComplete() {
        stopTimer()

        if state == .focusing {
            // Persist the focus session
            if let startTime = sessionStartTime {
                persistSession(startTime: startTime, isBreak: false, endTime: .now, pausedDuration: accumulatedPause)
            }
            completedPomodoros += 1

            // Transition to waiting for rest
            let interval = max(1, pomodorosBeforeLongBreak)
            let isLongBreak = completedPomodoros % interval == 0
            let breakMinutes = isLongBreak ? longBreakMinutes : shortBreakMinutes
            totalSeconds = breakMinutes * 60
            remainingSeconds = totalSeconds
            state = .waitingForRest
            // We keep the sessionStartTime nil or reset it until the user actually starts the break
            sessionStartTime = nil
            accumulatedPause = 0

            notificationService.sendNotification(
                title: Localization.string(for: "focus_complete", lang: language),
                body: Localization.string(for: isLongBreak ? "long_break_ready" : "short_break_ready", lang: language)
            )
            addLog(Localization.string(for: "focus_completed_waiting", lang: language))

            // Trigger sound and shine effect
            SoundService.shared.playCompletionSound()
            ShineEffectManager.shared.triggerShine()

        } else if state == .resting {
            // Persist the break session
            if let startTime = sessionStartTime {
                persistSession(startTime: startTime, isBreak: true, endTime: .now, pausedDuration: accumulatedPause)
            }

            notificationService.sendNotification(
                title: Localization.string(for: "break_complete", lang: language),
                body: Localization.string(for: "ready_to_focus", lang: language)
            )

            // Trigger sound and shine effect
            SoundService.shared.playCompletionSound()
            ShineEffectManager.shared.triggerShine()

            // Ready for next focus
            totalSeconds = focusDurationMinutes * 60
            remainingSeconds = totalSeconds
            state = .idle
            sessionStartTime = nil
            accumulatedPause = 0
            isUntimedBreak = false
        }
    }

    private func resetToIdle() {
        stopTimer()
        state = .idle
        totalSeconds = focusDurationMinutes * 60
        remainingSeconds = totalSeconds
        sessionStartTime = nil
        pauseStartedAt = nil
        accumulatedPause = 0
        isUntimedBreak = false
    }

    // MARK: – Persistence

    private func persistSession(startTime: Date, isBreak: Bool, endTime: Date, pausedDuration: TimeInterval = 0) {
        guard let context = modelContext else { return }

        // Use the most recent session's hourly rate if not specified,
        // though TimerSession will also check tags.
        let session = TimerSession(
            startTime: startTime.addingTimeInterval(pausedDuration),
            endTime: endTime,
            isBreak: isBreak,
            taskName: currentTaskName,
            isBillable: isBillable && !isBreak,
            hourlyRate: hourlyRate,
            tags: selectedTags
        )
        context.insert(session)
        try? context.save()
    }

    // MARK: – Presets

    func recentUniqueTasks() -> [TimerSession] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<TimerSession>(
            predicate: #Predicate<TimerSession> { !$0.isBreak },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        let allSessions = (try? context.fetch(descriptor)) ?? []

        var seenNames = Set<String>()
        var uniqueTasks: [TimerSession] = []

        for session in allSessions {
            if !seenNames.contains(session.taskName) {
                seenNames.insert(session.taskName)
                uniqueTasks.append(session)
            }
            if uniqueTasks.count >= 5 { break }
        }

        return uniqueTasks
    }

    func updateCurrentSession(taskName: String, tags: [Tag], durationMinutes: Int) {
        self.currentTaskName = taskName
        self.selectedTags = tags
        self.focusDurationMinutes = durationMinutes

        if state == .idle {
            totalSeconds = durationMinutes * 60
            remainingSeconds = totalSeconds
        }
    }
}
