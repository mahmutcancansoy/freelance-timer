import SwiftData
import Foundation

@Model
final class TimerSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var isBreak: Bool
    var taskName: String
    var isBillable: Bool
    var hourlyRate: Double

    @Relationship(inverse: \Tag.sessions)
    var tags: [Tag]

    var duration: TimeInterval {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return end.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        let total = Int(duration)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var billableAmount: Double {
        guard isBillable else { return 0 }
        let tagMaxRate = tags.compactMap { ($0.hourlyRate ?? 0) > 0 ? $0.hourlyRate : nil }.max()
        let rate = tagMaxRate ?? hourlyRate
        return (duration / 3600.0) * rate
    }

    init(
        startTime: Date = .now,
        endTime: Date? = nil,
        isBreak: Bool = false,
        taskName: String = "",
        isBillable: Bool = true,
        hourlyRate: Double = 75.0,
        tags: [Tag] = []
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.isBreak = isBreak
        self.taskName = taskName
        self.isBillable = isBillable
        self.hourlyRate = hourlyRate
        self.tags = tags
    }
}
