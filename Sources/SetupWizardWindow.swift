import SwiftUI
import AppKit

public struct SetupWizardView: View {
    var onComplete: () -> Void
    
    @State private var step = 0
    @State private var hasPermission = false
    @ObservedObject var preferences = Preferences.shared
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Header Indicator
            HStack {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(step == index ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top)
            
            // Slide Content
            Group {
                switch step {
                case 0:
                    WelcomeSlide()
                case 1:
                    PermissionSlide(hasPermission: $hasPermission)
                case 2:
                    DestinationsSetupSlide()
                case 3:
                    ThemeSlide()
                default:
                    CompletionSlide()
                }
            }
            .frame(height: 250)
            
            Spacer()
            
            // Navigation Buttons
            HStack {
                if step > 0 {
                    Button("Back") {
                        step -= 1
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if step < 4 {
                    Button("Next") {
                        step += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .frame(width: 550, height: 420)
        .onAppear {
            checkPermission()
        }
    }
    
    private func checkPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        hasPermission = AXIsProcessTrustedWithOptions(options)
    }
}

// MARK: - Welcome Slide
struct WelcomeSlide: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.forward.app.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.bottom, 10)
            
            Text("Welcome to ShakeShare")
                .font(.system(size: 24, weight: .bold))
            
            Text("Accelerate your file-sharing workflow with a simple gesture:")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                WorkflowBadge(text: "1. Drag File", icon: "doc.fill")
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                WorkflowBadge(text: "2. Shake Mouse", icon: "hand.wave.fill")
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                WorkflowBadge(text: "3. Drop to Share", icon: "square.and.arrow.up.fill")
            }
            .padding(.top, 10)
        }
    }
}

struct WorkflowBadge: View {
    var text: String
    var icon: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .frame(width: 100, height: 55)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Permission Slide
struct PermissionSlide: View {
    @Binding var hasPermission: Bool
    
    @State private var pollTimer: Timer? = nil
    @State private var isWaitingForUser = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Animated icon
            Image(systemName: hasPermission ? "lock.shield.fill" : "lock.shield")
                .font(.system(size: 50))
                .foregroundColor(hasPermission ? .green : .orange)
                .padding(.bottom, 5)
                .animation(.easeInOut(duration: 0.3), value: hasPermission)
            
            Text("Enable Accessibility Access")
                .font(.system(size: 20, weight: .bold))
            
            Text("ShakeShare needs Accessibility access to detect mouse shakes while you drag files in Finder and other apps.\n\nClick **Enable & Prompt** — macOS will show its permission dialog and register this exact version of ShakeShare automatically.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            if !hasPermission {
                VStack(spacing: 8) {
                    // Primary action: prompt via AX directly
                    Button("Enable & Prompt (Recommended)") {
                        // Prompt=true causes macOS to show its own dialog
                        // AND registers the exact current binary
                        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                        _ = AXIsProcessTrustedWithOptions(options)
                        // Start auto-polling for when user grants
                        startPolling()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    // Fallback: open settings manually
                    Button("Open System Settings manually") {
                        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                        if let url = URL(string: urlString) {
                            NSWorkspace.shared.open(url)
                        }
                        startPolling()
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: 11))
                }
                .padding(.top, 6)
            }
            
            // Status indicator
            HStack(spacing: 6) {
                if isWaitingForUser && !hasPermission {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 10, height: 10)
                    Text("Waiting for you to grant access...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                } else {
                    Circle()
                        .fill(hasPermission ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(hasPermission ? "✓ Accessibility Granted — you can proceed!" : "Accessibility not yet granted")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(hasPermission ? .green : .secondary)
                }
            }
            .padding(.top, 4)
            .animation(.easeInOut, value: hasPermission)
        }
        .onDisappear {
            stopPolling()
        }
    }
    
    private func startPolling() {
        isWaitingForUser = true
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let trusted = AXIsProcessTrusted()
            if trusted {
                hasPermission = true
                isWaitingForUser = false
                stopPolling()
            }
        }
    }
    
    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

// MARK: - Theme Slide
struct ThemeSlide: View {
    @ObservedObject var preferences = Preferences.shared
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Choose Your Style")
                .font(.system(size: 20, weight: .bold))
            
            Text("Select a visual style for the radial sharing wheel:")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                ThemeCard(title: "Light", type: .light, activeType: $preferences.theme)
                ThemeCard(title: "Dark", type: .dark, activeType: $preferences.theme)
                ThemeCard(title: "Frosted Glass", type: .glass, activeType: $preferences.theme)
                ThemeCard(title: "Flat Matte", type: .matte, activeType: $preferences.theme)
            }
            .padding(.top, 10)
        }
    }
}

struct ThemeCard: View {
    var title: String
    var type: ThemeType
    @Binding var activeType: ThemeType
    
    var body: some View {
        Button(action: { activeType = type }) {
            VStack(spacing: 8) {
                // Mini preview representation of the theme
                Circle()
                    .fill(backgroundForPreview(type))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(borderColorForPreview(type), lineWidth: 1.5)
                    )
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .frame(width: 95, height: 95)
            .background(activeType == type ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(activeType == type ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func backgroundForPreview(_ type: ThemeType) -> Color {
        switch type {
        case .light: return Color(white: 0.98)
        case .dark: return Color(white: 0.1)
        case .glass: return Color.purple.opacity(0.2)
        case .matte: return Color.mint.opacity(0.2)
        }
    }
    
    private func borderColorForPreview(_ type: ThemeType) -> Color {
        switch type {
        case .light: return Color(white: 0.8)
        case .dark: return Color(white: 0.3)
        case .glass: return Color.white.opacity(0.6)
        case .matte: return Color.clear
        }
    }
}

// MARK: - Completion Slide
struct CompletionSlide: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .padding(.bottom, 10)
            
            Text("You are all set!")
                .font(.system(size: 24, weight: .bold))
            
            Text("Try it out now:")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 6) {
                Label("Drag a file from Finder", systemImage: "arrow.up.right")
                Label("Shake the mouse back and forth rapidly", systemImage: "hand.wave")
                Label("Drop the file onto the AirDrop, Desktop, or Mail slots", systemImage: "square.and.arrow.up")
            }
            .font(.system(size: 12))
            .padding(.top, 10)
        }
    }
}

// MARK: - Permission Guidance View
public struct PermissionGuidanceView: View {
    var onGrantClicked: () -> Void
    var onCloseClicked: () -> Void
    
    public init(onGrantClicked: @escaping () -> Void, onCloseClicked: @escaping () -> Void) {
        self.onGrantClicked = onGrantClicked
        self.onCloseClicked = onCloseClicked
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)
                .padding(.top)
            
            Text("Accessibility Access Required")
                .font(.system(size: 16, weight: .bold))
            
            Text("To recognize mouse gestures while dragging files globally, macOS requires Accessibility permission.\n\nPlease open settings and check the box next to **ShakeShare**.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("Cancel", action: onCloseClicked)
                    .buttonStyle(.bordered)
                
                Button("Open Settings", action: onGrantClicked)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
        }
        .frame(width: 450, height: 320)
    }
}

// MARK: - Destinations Setup Slide
struct DestinationsSetupSlide: View {
    @ObservedObject var preferences = Preferences.shared
    @State private var selectedIndex = 0
    
    let icons = ["desktopcomputer", "doc.text", "folder", "envelope", "message", "wifi", "globe", "terminal", "app", "link", "arrow.up.forward.app.fill"]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Configure Your Destinations")
                .font(.system(size: 18, weight: .bold))
            
            Text("Customize what happens when you drop files onto the 8 wheel sectors:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
            
            HStack(spacing: 12) {
                // Left list of slots
                VStack(alignment: .leading, spacing: 2) {
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(0..<8) { index in
                                let dest = preferences.destinations[index]
                                Button(action: { selectedIndex = index }) {
                                    HStack {
                                        Image(systemName: dest.iconName)
                                            .font(.system(size: 11))
                                            .frame(width: 16)
                                        Text("\(index + 1): \(dest.name)")
                                            .font(.system(size: 11, design: .rounded))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(selectedIndex == index ? Color.accentColor : Color.clear)
                                    .foregroundColor(selectedIndex == index ? .white : .primary)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(width: 140, height: 160)
                    .background(Color(NSColor.controlBackgroundColor))
                    .border(Color(NSColor.gridColor), width: 0.5)
                    .cornerRadius(4)
                }
                
                Divider()
                
                // Right edit form
                let dest = preferences.destinations[selectedIndex]
                VStack(alignment: .leading, spacing: 6) {
                    Text("Slot \(selectedIndex + 1) Settings")
                        .font(.system(size: 12, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name").font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
                        TextField("e.g. Desktop", text: Binding(
                            get: { dest.name },
                            set: { updateDestination(index: selectedIndex, name: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Type").font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
                        Picker("", selection: Binding(
                            get: { dest.type },
                            set: { updateDestination(index: selectedIndex, type: $0) }
                        )) {
                            ForEach(DestinationType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.system(size: 11))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Address/Path").font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            TextField("Path or URL", text: Binding(
                                get: { dest.configuration },
                                set: { updateDestination(index: selectedIndex, configuration: $0) }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            
                            if dest.type == .folder {
                                Button("Browse") {
                                    browsePath(forFolder: true) { path in
                                        updateDestination(index: selectedIndex, configuration: path)
                                    }
                                }
                                .font(.system(size: 10))
                            } else if dest.type == .application {
                                Button("Browse") {
                                    browsePath(forFolder: false) { path in
                                        updateDestination(index: selectedIndex, configuration: path)
                                    }
                                }
                                .font(.system(size: 10))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 10)
    }
    
    private func updateDestination(
        index: Int,
        name: String? = nil,
        type: DestinationType? = nil,
        iconName: String? = nil,
        configuration: String? = nil
    ) {
        var list = preferences.destinations
        var dest = list[index]
        
        if let n = name { dest.name = n }
        if let t = type {
            dest.type = t
            switch t {
            case .folder: dest.iconName = "folder"
            case .email: dest.iconName = "envelope"
            case .messages: dest.iconName = "message"
            case .airDrop: dest.iconName = "wifi"
            case .application: dest.iconName = "app"
            case .url: dest.iconName = "globe"
            case .customScript: dest.iconName = "terminal"
            }
        }
        if let i = iconName { dest.iconName = i }
        if let c = configuration { dest.configuration = c }
        
        list[index] = dest
        preferences.destinations = list
    }
    
    private func browsePath(forFolder: Bool, completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = !forFolder
        panel.canChooseDirectories = forFolder
        panel.allowsMultipleSelection = false
        if !forFolder {
            panel.allowedContentTypes = [.application, .executable]
        }
        panel.begin { response in
            if response == .OK, let url = panel.url {
                completion(url.path)
            }
        }
    }
}
