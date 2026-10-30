import Testing
@testable import FreelanceTimer
import Foundation

struct SessionEngineTests {
    @Test func testTimerInitialization() {
        let engine = SessionEngine()
        #expect(engine.state == .idle)
        #expect(engine.remainingSeconds == 25 * 60)
    }

    @Test func testStartTimer() {
        let engine = SessionEngine()
        engine.start(customDurationMinutes: 10)
        #expect(engine.state == .focusing)
        #expect(engine.remainingSeconds == 10 * 60)
    }

    @Test func testPauseResume() {
        let engine = SessionEngine()
        engine.start(customDurationMinutes: 10)
        engine.pause()
        #expect(engine.state == .paused)
        engine.resume()
        #expect(engine.state == .focusing)
    }

    @Test func testStopSavesSession() {
        let engine = SessionEngine()
        engine.start(customDurationMinutes: 10)
        engine.stop()
        #expect(engine.state == .idle)
    }

    @Test func testUpdateCurrentSessionIncrementsTimer() {
        let engine = SessionEngine()
        engine.updateCurrentSession(taskName: "New Task", tags: [], durationMinutes: 45)
        #expect(engine.currentTaskName == "New Task")
        #expect(engine.focusDurationMinutes == 45)
        #expect(engine.remainingSeconds == 45 * 60)
    }
}
