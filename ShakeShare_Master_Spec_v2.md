# ShakeShare - Master Specification (Draft)

## Product Vision
ShakeShare is a macOS utility that accelerates file sharing using a simple workflow:

Drag → Shake → Drop

The user drags one or more files from Finder, shakes the mouse, a radial wheel appears, and the file is dropped onto a configured destination. The destination opens with the files attached and ready to send.

---

## Platform

- macOS 15 Sequoia+
- Direct-download DMG
- SwiftUI + AppKit
- Menu bar application

---

## Activation

The wheel only appears when:
1. The user is actively dragging file(s).
2. The user performs the configured mouse shake gesture.

If no file is being dragged:
- No wheel appears.
- No launcher functionality.

---

## Wheel Design

- Center-screen appearance
- Perfect circular layout
- Exactly 8 destinations
- Fade + scale animation
- ESC closes wheel
- Modern macOS-native design
- Inspired by reference screenshots, not a clone

---

## Destinations

Examples:
- WhatsApp contacts
- iMessage contacts
- Telegram chats
- Discord DMs
- Slack channels
- Mail recipients
- AirDrop devices
- Folders
- Cloud locations
- Websites
- Custom workflows

Destination model:
- Name
- Type
- Platform
- Avatar/icon
- Configuration
- Fallback options

---

## Sharing Behaviour

Workflow:
1. User drags file(s).
2. User shakes mouse.
3. Wheel appears.
4. User drops onto destination.
5. Destination opens.
6. Files are attached.
7. User reviews.
8. User presses Send.

Files are NEVER automatically sent.

---

## Configuration

### Setup Wizard
- First-launch wizard
- Skippable
- Configure up to 8 destinations
- Re-launchable from menu bar

### Themes
- Dark
- Light
- Glass
- Matte
- Custom theme options

### Preferences
- Shake sensitivity
- Activation delay
- Auto-close behaviour
- Failure handling mode
- App launch behaviour
- Multi-monitor preference
- Optional iCloud sync

---

## File Support

- Single files
- Multiple files
- Folders (where supported)

No artificial file limit.

---

## Failure Handling

User-selectable:

### Simple Mode
- Show error and stop

### Smart Mode
- Suggest alternative destinations

---

## Data Storage

- Local storage by default
- Optional iCloud sync
- No accounts
- No backend

---

## Non-Goals (V1)

Not:
- A launcher
- A dock replacement
- A chat client
- A workflow engine
- A productivity dashboard

---

## Claude Code Rules

1. Build MVP first.
2. Use provider architecture.
3. Do not fake integrations.
4. Implement only reliable integrations.
5. Never rewrite unchanged files.
6. Ask before major refactors.
7. Keep a PROJECT_MEMORY.md file.
8. Build incrementally.
9. Prefer native macOS APIs.
10. Minimize token usage by editing only affected files.

---

## Core Value

ShakeShare reduces:

Finder → Share → App → Contact → Attach → Send

into:

Drag → Shake → Drop


---

## Distribution & Packaging

### Deliverables
The project must produce:

- ShakeShare.app
- ShakeShare.dmg

### DMG Requirements
- Professional installer-style DMG
- Applications folder shortcut included
- Drag-to-install experience
- README included
- First-launch instructions included

### Compatibility
- Apple Silicon support required (M1, M2, M3, M4 and newer)
- Intel support optional

### Sharing
The generated DMG should be suitable for distribution to:
- Friends
- Family
- Small beta testers

### Permissions
On first launch, guide users through granting:
- Accessibility permissions
- Automation permissions
- Any other permissions required for file sharing integrations

### Claude Code Requirement
The build pipeline must include instructions for:
1. Building Release configuration
2. Creating ShakeShare.app
3. Packaging ShakeShare.dmg
4. Testing installation on a clean macOS system
