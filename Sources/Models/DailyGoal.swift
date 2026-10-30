import SwiftData
import Foundation

@Model
final class DailyGoal {
    var id: UUID
    var date: Date
    var targetSeconds: Int

    var targetFormatted: String {
        let hours = targetSeconds / 3600
        let minutes = (targetSeconds % 3600) / 60
        if minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(hours)h 00m"
    }

    init(date: Date = .now, targetSeconds: Int = 6 * 3600) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.targetSeconds = targetSeconds
    }
}
