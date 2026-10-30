import AppKit

@MainActor
final class SoundService {
    static let shared = SoundService()

    private init() {}

    func playCompletionSound() {
        // "Glass" is a calm, pleasant system sound on macOS
        if let sound = NSSound(named: "Glass") {
            sound.play()
        }
    }
}
