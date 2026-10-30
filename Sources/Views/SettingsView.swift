import SwiftUI

struct SettingsView: View {
    @Environment(SessionEngine.self) private var engine

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection

            ScrollView {
                VStack(spacing: 24) {
                    generalSettingsSection

                    timerSettingsSection

                    billingSettingsSection
                }
            }
        }
        .padding(24)
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.string(for: "settings", lang: engine.language))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text(Localization.string(for: "configure_experience", lang: engine.language))
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }

            Spacer()
        }
    }

    private var timerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localization.string(for: "timer_durations", lang: engine.language))
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                HStack {
                    Text(Localization.string(for: "focus_session", lang: engine.language))
                    Spacer()
                    TextField("", value: Bindable(engine).focusDurationMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                HStack {
                    Text(Localization.string(for: "short_break", lang: engine.language))
                    Spacer()
                    TextField("", value: Bindable(engine).shortBreakMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
                HStack {
                    Text(Localization.string(for: "long_break", lang: engine.language))
                    Spacer()
                    TextField("", value: Bindable(engine).longBreakMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }
            .padding(20)
            .glassPanel(cornerRadius: 16)
        }
    }

    private var billingSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localization.string(for: "billing_config", lang: engine.language))
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Text(Localization.string(for: "hourly_rate", lang: engine.language) + " ($)")
                Spacer()
                TextField("", value: Bindable(engine).hourlyRate, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            .padding(20)
            .glassPanel(cornerRadius: 16)
        }
    }

    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(Localization.string(for: "general", lang: engine.language))
                .font(.headline)
                .foregroundStyle(.white)

            HStack {
                Text(Localization.string(for: "language", lang: engine.language))
                Spacer()

                Picker("", selection: Bindable(engine).language) {
                    ForEach(Language.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding(20)
            .glassPanel(cornerRadius: 16)
        }
    }
}
