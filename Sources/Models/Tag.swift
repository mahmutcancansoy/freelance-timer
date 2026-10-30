import SwiftData
import Foundation

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var hourlyRate: Double? = 0.0
    var sessions: [TimerSession]

    init(name: String, colorHex: String, hourlyRate: Double? = 0.0) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.hourlyRate = hourlyRate
        self.sessions = []
    }

    static let seedTags: [(String, String)] = [
        ("Design System", "#A855F7"),
        ("Development", "#3B82F6"),
        ("Meeting", "#F97316"),
        ("Client Work", "#EF4444"),
        ("Research", "#06B6D4"),
        ("Admin", "#8B5CF6")
    ]
}
