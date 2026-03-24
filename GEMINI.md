# FocusBrowser

FocusBrowser is a productivity-oriented macOS web browser built with Objective-C, Cocoa, and WebKit. It is designed to help users maintain deep work states by integrating essential focus tools directly into the browsing experience.

## Project Overview

- **Purpose**: A browser that minimizes distractions and provides built-in tools for focus and productivity.
- **Key Features**:
  - **Apple-Inspired UI**: Clean, minimalist design with a "Broken White" (#F5F5F7) background and soft black typography (#1D1D1F).
  - **Optimized Performance**: Fine-tuned WKWebView configurations for reduced CPU/Memory usage and smoother scrolling.
  - **Focus Sidebar**: A command center for productivity tools.
  - **Focus Timer**: A Pomodoro-style timer with "Flow" and "Break" states.
  - **Smart Site Blocker**: High-precision domain matching (suffix-based) to block distractions during focus sessions.
  - **Ambient Sounds**: Background audio (Rain, Forest, etc.) to mask environmental noise.
  - **Quick Notes**: A scratchpad for thoughts without leaving the browser.
  - **Breathing Exercises**: Guided relaxation tools.
  - **Focus Dashboard**: Statistics on focus time, blocked sites, and completed goals.
  - **Zen Mode**: A simplified interface that hides UI clutter during deep work.

## Technical Architecture

- **Language**: Objective-C with Automatic Reference Counting (ARC).
- **Optimization Strategy**: 
  - Resource usage reduction by disabling unnecessary media features (AirPlay, Autoplay).
  - Improved memory management in task-heavy components like `DownloadManager`.
  - Sophisticated theme engine for instant, system-wide visual updates.
- **Frameworks**:
  - `Cocoa (AppKit)`: Main UI and window management.
  - `WebKit`: Core browser engine with custom optimizations and content filtering.
  - `AVFoundation`: Audio playback for ambient sounds.
  - `QuartzCore`: Animations and UI transitions.
  - `UserNotifications`: System-level notifications for timer events.

### Core Components

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
