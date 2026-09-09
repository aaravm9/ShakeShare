# Project Memory: ShakeShare

## Project Goals
ShakeShare is a macOS utility that enables rapid file sharing via a "Drag → Shake → Drop" workflow. The user drags files from Finder, shakes the mouse, and drops them onto one of 8 radial destinations on the screen.

## Core Architecture
1. **Background Agent (`main.swift` & `AppDelegate.swift`)**:
   - Menu bar status item.
   - Monitors global drag events and checks for a shake gesture when the left mouse button is pressed.
2. **Gesture Recognition (`ShakeDetector.swift`)**:
   - Analyzes mouse speed and direction changes to detect a shake during dragging.
3. **Transparent Drag Overlay (`OverlayPanel.swift`)**:
   - A full-screen, borderless, floating, non-activating `NSPanel`.
   - Captures Drag & Drop events via native Cocoa drag protocols.
4. **Radial UI (`WheelView.swift` & `ThemeManager.swift`)**:
   - A SwiftUI circle with exactly 8 segments.
   - Fades and scales in under the mouse or in the center.
   - Computes segment highlights mathematically based on mouse angles.
5. **Onboarding & Settings (`SetupWizardWindow.swift` & `PreferencesWindow.swift`)**:
   - Handles accessibility permission checks and configuring sharing slots.

## Progress & Status
- **2026-06-02**: Initialized codebase structure and implementation plan. Approved by user.
- **2026-06-02**: Completed all module implementations.
- **2026-06-02**: Successfully compiled `ShakeShare.app` and packaged `ShakeShare.dmg`. Verified all paths and options.
- **2026-06-02**: Fixed a bug in `OverlayPanel`'s pasteboard reader (`NSURL` list bridging) to resolve drop execution issues. Added a new interactive onboarding slide to `SetupWizardView` to configure the 8 destinations during setup.
- **2026-06-02**: Generated a high-resolution app logo, wrote `generate_icns.sh` to compile it to macOS standard `ShakeShare.icns` using native `sips` and `iconutil` tools, and integrated it into the app bundle resources and `Info.plist`.
