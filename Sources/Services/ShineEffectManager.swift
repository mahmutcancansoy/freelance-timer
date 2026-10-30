import SwiftUI
import AppKit

@MainActor
final class ShineEffectManager {
    static let shared = ShineEffectManager()

    private var shinePanels: [NSPanel] = []

    private init() {}

    func triggerShine() {
        clearExistingPanels()

        let screens = NSScreen.screens
        for screen in screens {
            createShinePanel(for: screen)
        }

        // Auto-clear after animation duration (e.g., 3 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            self.clearExistingPanels()
        }
    }

    private func createShinePanel(for screen: NSScreen) {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar // Very high level
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = false

        let contentView = NSHostingView(rootView: ShineBorderView())
        panel.contentView = contentView

        panel.orderFrontRegardless()
        shinePanels.append(panel)
    }

    private func clearExistingPanels() {
        for panel in shinePanels {
            panel.close()
        }
        shinePanels.removeAll()
    }
}

struct ShineBorderView: View {
    @State private var opacity: Double = 0.0
    @State private var phase: CGFloat = 0.0

    var body: some View {
        ZStack {
            Rectangle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [.ftPrimary, .blue, .purple, .ftPrimary]),
                        center: .center,
                        angle: .degrees(Double(phase))
                    ),
                    lineWidth: 12
                )
                .blur(radius: 8)
                .opacity(opacity)

            Rectangle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [.ftPrimary, .white, .ftPrimary, .white, .ftPrimary]),
                        center: .center,
                        angle: .degrees(Double(phase))
                    ),
                    lineWidth: 4
                )
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1.0
            }

            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                phase = 360
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 0.0
                }
            }
        }
        .ignoresSafeArea()
    }
}
