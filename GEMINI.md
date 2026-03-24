# FocusBrowser

FocusBrowser is a productivity-oriented macOS web browser built with Objective-C, Cocoa, and WebKit. It is designed to help users maintain deep work states by integrating essential focus tools directly into the browsing experience.

## Recent Improvements

- **Memory Optimization**: Implemented intelligent **Tab Suspension** (Sekme Askıya Alma). Inactive tabs' web views are discarded when many tabs are open to maintain peak performance and low RAM usage.
- **Smooth Transitions**: Added hardware-accelerated fade-in/out animations for tab switching, providing a more refined and Apple-like experience.
- **Enhanced Sidebar**: Refined typography and spacing using SF Pro Bold/Medium for a more modern productivity dashboard.
- **History Management**: Added `HistoryManager` to record and store browsing history using secure coding.
- **Enhanced Settings**: Completely redesigned Settings UI using `NSStackView` and modern Apple-inspired aesthetics.
- **Improved Zen Mode**: Added hover-to-reveal functionality for the navigation bar during focus sessions.
- **Search Engine Integration**: Fully integrated customizable search engines (Google, DuckDuckGo, Bing).
- **Start Page v2**: Upgraded the internal start page with live stats and a cleaner Apple-style design.

## Technical Architecture

- **Language**: Objective-C with Automatic Reference Counting (ARC).
- **Optimization Strategy**: 
  - Resource usage reduction by disabling unnecessary media features.
  - Efficient history and session persistence using `NSUserDefaults` and `NSSecureCoding`.
- **Core Components**:
  - `HistoryManager`: Handles persistence of visited URLs.
  - `SettingsManager`: Manages user preferences like homepage and search engine.
  - `FocusEngine`: The heart of the productivity features.

## Building and Running

1. **Build**: Run `./FocusBrowser/build.sh`.
2. **Push**: Changes are pushed to `https://github.com/emrek0ca/bro-wse`.

- **`AppDelegate`**: Entry point; manages the main window and session restoration.
- **`MainWindowController`**: Coordinates tabs, the focus sidebar, and the overall window state.
- **`FocusEngine`**: The central state machine for focus sessions (Idle, Flow, Break).
- **`SiteBlocker` / `AdBlockManager`**: Handle content filtering and domain blocking using WebKit's rule-based system.
- **`AmbientSoundManager`**: Manages background audio playback.
- **`FocusSessionManager`**: Records and tracks history of focus sessions.
- **`ThemeManager`**: Handles visual themes and state-based color changes (e.g., green for Flow, blue for Break).

## Building and Running

The project includes a standalone build script that compiles all source files and packages them into a macOS application bundle.

- **Build Script**: `FocusBrowser/build.sh`
- **Build Command**:
  ```bash
  cd FocusBrowser
  ./build.sh
  ```
- **Output**: The compiled application is located at `FocusBrowser/build/FocusBrowser.app`.
- **Run Command**:
  ```bash
  open FocusBrowser/build/FocusBrowser.app
  ```

## Development Conventions

- **Singletons**: Most core managers (e.g., `FocusEngine`, `SessionManager`, `ThemeManager`) use the `sharedManager` or `sharedEngine` pattern for global access.
- **Notifications**: Communication between managers and UI is often handled via `NSNotificationCenter` (e.g., `FocusStateDidChangeNotification`).
- **Memory Management**: The project uses Automatic Reference Counting (ARC).
- **Resources**: HTML/JS resources for internal pages (like `start.html`) are located in `FocusBrowser/Resources`.
- **Rules**: Content blocking rules are defined in `FocusBrowser/blocker_rules.json`.

## Key Files

- `main.m`: The standard entry point for the Cocoa application.
- `AppDelegate.m`: Manages application lifecycle and session initialization.
- `MainWindowController.m`: Contains the bulk of the UI logic for tab management and the focus sidebar.
- `FocusEngine.m`: Implementation of the Pomodoro state machine.
- `USER_MANUAL.md`: User-facing documentation in Turkish (Kullanım Kılavuzu).
