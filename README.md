# Nexus Shell

A native iOS SSH terminal client for managing remote server connections and executing commands from your iPhone or iPad.

## Features

### Server Management
- Add, edit, delete, and list SSH server configurations
- Password and private key (PEM) authentication, stored securely in iOS Keychain
- Server groups (Production, Staging, Development, Personal) with custom icons and colors
- Freeform tag system with search support (name, host, username, tags)
- Connection test from the edit screen before saving
- Per-server color picker with hex color codes
- Swipe actions: left to edit, right to delete

### Terminal
- Full interactive SSH shell via NMSSH with PTY allocation
- ANSI escape code parsing: 16 standard colors, 16 bright colors, 24-bit RGB, bold, italic, underline, dim, blink, reverse, strikethrough
- Monospaced terminal output with auto-scroll and text selection
- Special keys toolbar: ESC, Tab, Ctrl+C, Ctrl+D, Ctrl+Z, arrow keys
- Command history navigation (up/down arrows)
- Quick commands: one-tap pre-configured commands by category (System, Network, Docker, Files)
- Font size controls (10-24) and font family picker (Menlo, SF Mono, Courier, Monaco)
- Color-coded connection status bar (green/orange/red/gray)
- Configurable scrollback limit (default 10,000 lines)
- Dynamic terminal resize with PTY size negotiation

### SSH Service
- Auto-reconnect: up to 3 attempts with configurable delay
- Keep-alive pings to prevent idle disconnection
- Configurable connection timeout (5-60s) and command timeout (10-120s)
- Session state machine: Disconnected, Connecting, Connected, Reconnecting, Error

### Security
- Keychain storage with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Biometric lock: Face ID / Touch ID / Optic ID with password fallback
- Configurable auto-lock timeout (1 min, 5 min, 15 min, or never)

### Settings
- Security: biometric toggle, auto-lock timeout
- SSH: default port, connection/command timeout sliders
- Terminal: font size, font family, haptic feedback toggle
- Appearance: language (English / Simplified Chinese), color scheme (System / Light / Dark)
- Quick Commands: view, delete, add custom commands with icon and category
- Data: clear command history, reset to defaults

### Localization
- English and Simplified Chinese (zh-Hans)
- Runtime language switching with immediate effect
- All user-facing strings localized via `Localizable.xcstrings`

## Architecture

MVVM pattern with `@Observable` (Swift Observation framework) ViewModels.

```
App/                    App entry point
Models/                 SwiftData @Model classes (Server, ServerGroup, CommandHistory, QuickCommand, TerminalBuffer)
ViewModels/             @Observable business logic classes
Views/
  ContentView.swift     Root tab bar + biometric lock
  Servers/              Server list and edit views
  Terminal/             Terminal view and toolbar
  Settings/             Settings view
  Components/           Reusable UI components
Services/               SSHService, KeychainService, BiometricService, CommandHistoryService
Utilities/              ANSIParser, Extensions
Resources/              Info.plist, Assets.xcassets, Localizable.xcstrings
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | SwiftUI |
| Persistence | SwiftData |
| State Management | Swift Observation (`@Observable`) |
| SSH | NMSSH (libssh2) via local Swift Package |
| Biometrics | LocalAuthentication |
| Credentials | Security.framework (Keychain) |
| Haptics | UIKit (`UIImpactFeedbackGenerator`) |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9
- iPhone and iPad

## Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project nexus_shell.xcodeproj \
  -scheme nexus_shell \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

## License

MIT
