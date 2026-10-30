# FreelanceTimer

FreelanceTimer is a native macOS time-tracking app for freelancers. It combines focus and break timers with task and tag tracking, daily goals, billing estimates, reports, and quick controls in the menu bar.

The app is built with SwiftUI and SwiftData. Its interface is available in **English** and **Turkish**.

## Features

- Focus timer with configurable focus, short-break, and long-break durations
- Timed and untimed breaks, plus pause, resume, reset, skip, and stop controls
- Tasks, reusable recent-task presets, and color-coded tags
- Billable and non-billable sessions with hourly-rate estimates
- Daily focus goal, session history, project summaries, and weekly activity
- Menu bar controls for checking and managing the active timer
- Local data storage with SwiftData
- English and Turkish interface, with the language preference saved between launches

## Requirements

- macOS 15 (Sequoia) or later
- Xcode 16 or later, including the Swift 6 toolchain

## Run the app

Clone the repository and launch the Swift package:

```bash
git clone https://github.com/mahmutcancansoy/freelance-timer.git
cd freelance-timer
swift run
```

You can also open the package in Xcode:

```bash
open Package.swift
```

Select **My Mac** as the run destination, then press **⌘R**. macOS notification behavior may depend on running the app as a bundled application rather than directly through Swift Package Manager.

## Use the app

1. Create or select a task and choose its tags.
2. Set the task duration if you want to override the configured focus duration.
3. Start the focus timer. Pause or resume it as needed; completed sessions appear in History and update the dashboard.
4. Start a suggested break after a focus session, or use one of the break presets while the timer is idle.
5. Set your hourly rate and daily goal in Settings and the right-hand dashboard panel.

The language can be changed in **Settings → General**. On first launch, the app follows the system language when it is Turkish; otherwise it starts in English.

## Project layout

```text
Sources/
├── App/          App entry point and window/menu bar setup
├── Engine/       Timer state and session lifecycle
├── Models/       SwiftData models for sessions, tags, and daily goals
├── Services/     Localization, analytics, notifications, tagging, and sound
├── Theme/        Colors and shared visual styles
└── Views/        Dashboard, timer, projects, reports, history, and settings
Tests/            Swift Testing tests
```

## Build and tests

```bash
swift build
swift test
```

## Contributing

Contributions are welcome. Bug reports, feature ideas, translations, and code improvements are all useful.

1. Check the existing issues first, or open an issue to discuss a larger change.
2. Fork the repository and create a focused branch from its default branch.
3. Make the change and add or update tests when appropriate.
4. Run `swift build` and `swift test` locally.
5. Open a pull request with a clear summary, the reason for the change, and any relevant screenshots for UI updates.

### Translation contributions

English and Turkish strings currently live in `Sources/Services/Localization.swift`. When adding a user-facing string, add it in both languages and use the localization helper in views instead of hard-coding the text. Please keep date, time, and duration output appropriate for the selected language as well.

### Contribution guidelines

- Keep pull requests focused and describe user-visible behavior changes.
- Follow the existing Swift and SwiftUI patterns where practical.
- Avoid committing personal data, local database files, signing credentials, or generated build artifacts.
- If a change affects stored data or timer behavior, explain the impact in the pull request.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for the full text.

## Acknowledgments

Built with Swift, SwiftUI, SwiftData, and Apple's Observation framework.
