#!/bin/bash

# Focus Browser Build Script
set -e

APP_NAME="FocusBrowser"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "Building Focus Browser..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy Info.plist
cp Info.plist "$CONTENTS_DIR/"
cp Resources/* "$RESOURCES_DIR/"

# Compile all source files
clang -fobjc-arc -O2 \
    -framework Cocoa \
    -framework WebKit \
    -framework QuartzCore \
    -framework AVFoundation \
    -framework UserNotifications \
    -o "$MACOS_DIR/$APP_NAME" \
    main.m \
    AppDelegate.m \
    MainWindowController.m \
    BrowserTab.m \
    TabButton.m \
    FindBar.m \
    FocusEngine.m \
    SessionManager.m \
    SettingsManager.m \
    SettingsWindowController.m \
    BookmarkManager.m \
    BookmarksWindowController.m \
    SiteBlocker.m \
    FocusStats.m \
    FocusSessionManager.m \
    DailyGoals.m \
    QuickNotesPanel.m \
    BreathingExerciseView.m \
    AmbientSoundManager.m \
    FocusDashboardController.m \
    BlockedPageView.m \
    ThemeManager.m \
    HistoryManager.m \
    FocusTimerView.m \
    AdBlockManager.m \
    DownloadManager.m \
    2>&1

echo "Build complete: $APP_BUNDLE"
echo "Launching..."
# open "$APP_BUNDLE"
