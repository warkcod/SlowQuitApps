# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SlowQuitApps** is a macOS application that adds a global delay to the Cmd-Q keyboard shortcut. Instead of quitting immediately when Cmd-Q is pressed, users must hold the key combination for a configurable duration (default: 1 second) before the application will quit. This prevents accidental app quits.

The app consists of:
- **Main Application** (SlowQuitApps): Background agent that intercepts global keyboard events
- **Launcher** (SlowQuitAppsLauncher): Helper app for auto-start functionality
- **Command-line Tool** (sqa): Management script for configuring and controlling the app

## Architecture

### Core Components

**SQAAppDelegate** (`SQAAppDelegate.m`)
- Main application delegate that runs as a background agent (`LSUIElement = true`)
- Registers a global CGEventTap to monitor keyboard events (Cmd, Q, Tab, modifiers)
- Detects Cmd-Q key sequences and delegates to state machine
- Handles accessibility permission checks
- Manages event tap port and run loop sources
- Identifies the active application to determine if Cmd-Q should be intercepted
- Prevents interference with the App Switcher (Cmd-Tab)

**SQAStateMachine** (`SQAStateMachine.m`)
- State machine managing the Cmd-Q hold process
- States: Initialized, Holding, Completed, Cancelled
- Uses GCD dispatch timer (15ms interval) to track hold progress
- Callbacks: onStart, onHolding, onCancelled, onCompletion
- Calculates progress percentage based on elapsed time vs. configured delay
- Cancels automatically if Command key is released before Q

**SQAOverlayWindowController** (`SQAOverlayWindowController.m`)
- Manages visual overlay displayed during the hold delay
- Shows progress bar with remaining time
- Displays the target application's name
- Only shown if `displayOverlay` preference is enabled
- Window positioned at screen center with transparent background

**SQAQResolver** (`SQAQResolver.m`)
- Resolves keyboard layout to find the physical Q key position
- Supports various keyboard layouts (QWERTY, Dvorak, etc.)
- Queries current keyboard input source via Text Input Services (TIS)

**SQAPreferences** (`SQAPreferences.m`)
- Manages user preferences using NSUserDefaults
- Preferences:
  - `delay`: Hold duration in milliseconds (default: 1000)
  - `whitelist`: Array of bundle IDs that bypass the delay
  - `invertList`: If YES, only whitelisted apps are affected
  - `displayOverlay`: Show/hide the progress overlay (default: YES)
  - `disableAutostart`: Disable auto-start on login (default: NO)

**SQADialogs** (`SQADialogs.m`)
- Displays system dialogs for user interaction
- Informs about accessibility permission requirements
- Handles hotkey registration failures

**SQAAutostart** (`SQAAutostart.m`)
- Manages automatic start on login
- Registers SlowQuitAppsLauncher in Login Items
- Toggles auto-start functionality

### Key Functions

**Global Event Handling** (in `SQAAppDelegate.m`)
```objective-c
CGEventRef eventTapHandler(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *userInfo)
```
- Intercepts all keyboard events system-wide
- Detects Command + Q combination
- Detects Command + Tab (App Switcher) to avoid interference
- Filters out screen lock activation (Cmd + Ctrl + Q)
- Clears the event flags and modifies keycode to prevent native app from receiving Cmd-Q

**Active Application Detection**
```objective-c
NSRunningApplication* findActiveApp()
```
- Uses `NSWorkspace menuBarOwningApplication` to get the active app
- Excludes Finder from Cmd-Q interception
- Checks against whitelist/blacklist based on `invertList` preference

## Building the Project

**Prerequisites:**
- Xcode 14.3 or later
- macOS SDK (deployment target: macOS 10.14)
- Command Line Tools

**Build Configurations:**
- **Debug**: Optimization level 0, enables debugging symbols
- **Release**: Optimization enabled for production builds

**Build Commands:**
```bash
# Open in Xcode
open SlowQuitApps.xcodeproj

# Build from command line
xcodebuild -project SlowQuitApps.xcodeproj -scheme SlowQuitApps build

# Build Release configuration
xcodebuild -project SlowQuitApps.xcodeproj -scheme SlowQuitApps -configuration Release build

# Archive for distribution
xcodebuild -project SlowQuitApps.xcodeproj -scheme SlowQuitApps archive
```

**Targets:**
- `SlowQuitApps`: Main application
- `SlowQuitAppsLauncher`: Auto-start helper app
- `SlowQuitAppsTests`: Unit test bundle (currently empty)

## Running and Testing

**Run the App:**
```bash
# From Xcode: Product → Run (Cmd+R)
# From command line:
open build/Debug/SlowQuitApps.app
```

**Run Tests:**
```bash
# From Xcode: Product → Test (Cmd+U)
xcodebuild test -project SlowQuitApps.xcodeproj -scheme SlowQuitApps
```

**Note:** The test suite (`SlowQuitAppsTests.m`) is currently empty with a single failing test placeholder.

## Key Configuration Files

- `SlowQuitApps-Info.plist`: Main app bundle configuration
  - Bundle ID: `com.dteoh.SlowQuitApps`
  - Version: `0.8.2`
  - Set as `LSUIElement = true` (no dock icon, menu bar)

- `project.pbxproj`: Xcode project file containing:
  - Build settings
  - Target configurations
  - Source file references
  - Build phases

## Command-Line Management Tool

**sqa** (`Executables/sqa`): Command-line interface for managing SlowQuitApps

Common commands:
```bash
# App control
sqa start          # Launch SlowQuitApps
sqa stop           # Stop SlowQuitApps
sqa restart        # Restart SlowQuitApps

# Installation
sqa install        # Install via Homebrew
sqa update         # Update via Homebrew
sqa uninstall      # Uninstall via Homebrew

# Configuration
sqa config                    # Show current settings
sqa delay 5000                # Set delay to 5 seconds
sqa overlay on                # Enable overlay
sqa overlay off               # Disable overlay
sqa whitelist add Notes       # Add Notes.app to whitelist
sqa whitelist ls              # List whitelisted apps
sqa whitelist clear           # Clear all whitelisted apps

# Other
sqa doc            # Open documentation
sqa help           # Show help
```

## Maintenance Script

**killAndStart.sh**: Bash script for auto-restart functionality
- Kills existing SlowQuitApps process
- Launches the app from `/Applications/`
- Includes retry logic for failed launches
- Logs to `/tmp/killAndStart.log`
- Can be scheduled via cron (e.g., every 30 minutes)

## Development Notes

- **Accessibility Permissions**: The app requires Accessibility permissions to monitor global keyboard events. In Debug builds, this check is bypassed.
- **Privacy**: App monitors keyboard input system-wide and identifies active applications.
- **Auto-start**: Uses Login Items via a separate launcher app (common pattern for sandboxed apps needing auto-start).
- **Keyboard Layout**: The QResolver handles different keyboard layouts to find the Q key position.
- **Memory Management**: Uses manual reference counting (MRC) for CFRunLoop and CFMachPort types, ARC for Objective-C objects.

## Preferences Storage

All preferences are stored in `NSUserDefaults` under domain `com.dteoh.SlowQuitApps`:
```bash
# Read all preferences
defaults read com.dteoh.SlowQuitApps

# Set delay to 2 seconds
defaults write com.dteoh.SlowQuitApps delay -int 2000

# Add to whitelist
defaults write com.dteoh.SlowQuitApps whitelist -array-add com.apple.Notes

# Enable blacklist mode (only affect whitelisted apps)
defaults write com.dteoh.SlowQuitApps invertList -bool YES
```
