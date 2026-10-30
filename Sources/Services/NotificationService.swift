import Foundation
import UserNotifications

final class NotificationService: @unchecked Sendable {

    func requestPermission() {
        // UNUserNotificationCenter requires a proper app bundle
        // Check if we're running as a bundled app before requesting
        guard Bundle.main.bundleIdentifier != nil,
              ProcessInfo.processInfo.environment["__CFBundleIdentifier"] != nil ||
              Bundle.main.bundlePath.hasSuffix(".app") else {
            print("[NotificationService] Skipping permission — not running as bundled .app")
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notifications \(granted ? "granted" : "denied")")
            }
        }
    }

    func sendNotification(title: String, body: String) {
        // Gracefully degrade if not running as bundled app
        guard Bundle.main.bundleIdentifier != nil else {
            print("🔔 \(title): \(body)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Fire immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Fallback to console output
                print("🔔 \(title): \(body)")
            }
        }
    }
}
