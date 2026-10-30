import SwiftUI

struct TimerView: View {
    @Environment(SessionEngine.self) private var engine

    var body: some View {
        VStack(spacing: 0) {
            // Active task pill
            activeTaskPill
                .padding(.bottom, 32)

            // Timer circle
            timerCircle
                .padding(.bottom, 48)

            // Controls
            timerControls
        }
    }

    // MARK: – Task Pill

    private var activeTaskPill: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(engine.state == .focusing ? Color.red : (engine.state == .resting ? Color.ftPrimary : Color.gray))
                .frame(width: 8, height: 8)
                .modifier(PulseModifier(isActive: engine.state == .focusing || engine.state == .waitingForRest))

            Text(Localization.string(for: "current_task", lang: engine.language))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray)

            Text(engine.currentTaskName.isEmpty ? Localization.string(for: "placeholder_task", lang: engine.language) : engine.currentTaskName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            if engine.isBillable {
                Button(action: { engine.isBillable.toggle() }) {
                    Text(Localization.string(for: "billable", lang: engine.language))
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.ftPrimary.opacity(0.3))
                        )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: { engine.isBillable.toggle() }) {
                    Text(Localization.string(for: "non_billable", lang: engine.language))
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .glassPanel(cornerRadius: 999)
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 20)
    }

    // MARK: – Timer Circle

    private var timerCircle: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .frame(width: 320, height: 320)

            // Dashed ring
            Circle()
                .stroke(Color.white.opacity(0.03), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(width: 288, height: 288)

            // Background track
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 8)
                .frame(width: 260, height: 260)

            // Progress arc
            Circle()
                .trim(from: 0, to: engine.progress)
                .stroke(
                    Color.ftPrimary,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.ftPrimary.opacity(0.4), radius: 15)
                .animation(.easeInOut(duration: 0.5), value: engine.progress)

            // Timer text
            VStack(spacing: 8) {
                Text(engine.formattedTime)
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: engine.formattedTime)

                Text(Localization.string(for: engine.state.localizationKey, lang: engine.language).uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(Color.ftPrimary.opacity(0.8))
            }
        }
    }

    // MARK: – Controls

    private var timerControls: some View {
        HStack(spacing: 16) {
            // Reset
            Button(action: {
                print("[Timer] Reset clicked")
                engine.reset()
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18))
                    .foregroundStyle(.gray)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.ftSurfaceDark)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)

            // Play / Pause / Start Break
            if engine.state == .waitingForRest {
                Button(action: {
                    print("[Timer] Start Break clicked")
                    engine.startBreak(minutes: nil)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cup.and.saucer.fill")
                        Text(Localization.string(for: "start_break", lang: engine.language))
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 160, height: 56)
                    .background(
                        Capsule()
                            .fill(Color.ftPrimary)
                            .neonGlow()
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    print("[Timer] Play/Pause clicked")
                    engine.togglePauseResume()
                }) {
                    Image(systemName: engine.state == .paused || engine.state == .idle ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                        .frame(width: 96, height: 56)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            // Stop (Save to History)
            Button(action: {
                print("[Timer] Save clicked")
                engine.stop()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text(Localization.string(for: "save", lang: engine.language))
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.ftPrimary.opacity(0.2))
                        .overlay(
                            Circle()
                                .stroke(Color.ftPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            // Skip
            Button(action: {
                print("[Timer] Skip clicked")
                engine.skip()
            }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(engine.state == .focusing ? .gray.opacity(0.5) : .white.opacity(0.8))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(engine.state == .focusing ? Color.white.opacity(0.05) : Color.ftPrimary.opacity(0.2))
                    )
            }
            .buttonStyle(.plain)
            .disabled(engine.state == .idle)
        }
    }
}

// MARK: – Pulse Animation

struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(
                isActive
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default,
                value: scale
            )
            .onAppear {
                if isActive { scale = 1.5 }
            }
            .onChange(of: isActive) { _, newValue in
                scale = newValue ? 1.5 : 1.0
            }
    }
}
