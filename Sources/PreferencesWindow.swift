import SwiftUI
import AppKit

public struct PreferencesView: View {
    @EnvironmentObject var preferences: Preferences
    @State private var activeTab = 0
    @State private var selectedDestinationIndex = 0
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Tab Header
            HStack(spacing: 20) {
                Button(action: { activeTab = 0 }) {
                    VStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                        Text("General")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(activeTab == 0 ? .accentColor : .secondary)
                    .frame(width: 60)
                }
                .buttonStyle(.plain)
                
                Button(action: { activeTab = 1 }) {
                    VStack(spacing: 4) {
                        Image(systemName: "safari.fill")
                            .font(.system(size: 18))
                        Text("Destinations")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(activeTab == 1 ? .accentColor : .secondary)
                    .frame(width: 80)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Tab Content
            if activeTab == 0 {
                GeneralSettingsView()
                    .padding()
            } else {
                DestinationsSettingsView(selectedIndex: $selectedDestinationIndex)
                    .padding()
            }
            
            Spacer()
        }
        .frame(width: 620, height: 480)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Slider(value: $preferences.shakeSensitivity, in: 1.0...10.0, step: 0.5) {
                        Text("Shake Sensitivity:")
                            .frame(width: 140, alignment: .trailing)
                    } minimumValueLabel: {
                        Text("Low")
                    } maximumValueLabel: {
                        Text("High")
                    }
                    Text("Adjust how hard you need to shake the mouse to activate the wheel.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.leading, 150)
                }
                
                Spacer().frame(height: 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Slider(value: $preferences.activationDelay, in: 0.0...1.0, step: 0.05) {
                        Text("Activation Delay:")
                            .frame(width: 140, alignment: .trailing)
                    } minimumValueLabel: {
                        Text("Instant")
                    } maximumValueLabel: {
                        Text("1.0s")
                    }
                    Text("Add a small buffer time before the wheel triggers to prevent accidental shows.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.leading, 150)
                }
            }
            
            Divider().padding(.vertical, 10)
            
            Section {
                Picker("Theme Style:", selection: $preferences.theme) {
                    Text("Light").tag(ThemeType.light)
                    Text("Dark").tag(ThemeType.dark)
                    Text("Frosted Glass").tag(ThemeType.glass)
                    Text("Flat Matte").tag(ThemeType.matte)
                }
                .pickerStyle(.inline)
                .frame(width: 320)
                
                Spacer().frame(height: 10)
                
                Picker("Failure Handling:", selection: $preferences.failureHandling) {
                    Text("Simple (Show alert and stop)").tag("simple")
                    Text("Smart (Suggest alternatives)").tag("smart")
                }
                .pickerStyle(.radioGroup)
                
                Spacer().frame(height: 10)
                
                Toggle("Auto-close wheel after drop", isOn: $preferences.autoClose)
                
                Toggle("Launch ShakeShare at Login", isOn: $preferences.appLaunchAtLogin)
            }
        }
    }
}

// MARK: - Destinations Tab

struct DestinationsSettingsView: View {
    @EnvironmentObject var preferences: Preferences
    @Binding var selectedIndex: Int
    
    let icons = ["desktopcomputer", "doc.text", "folder", "envelope", "message", "wifi", "globe", "terminal", "app", "link", "arrow.up.forward.app.fill", "tray.and.arrow.up.fill", "arrow.turn.up.forward.right"]
    
    var body: some View {
        HStack(spacing: 15) {
            // Left List: 8 Slots
            VStack(alignment: .leading, spacing: 4) {
                Text("Sharing Slots (Exactly 8)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(0..<8) { index in
                            let dest = preferences.destinations[index]
                            Button(action: { selectedIndex = index }) {
                                HStack {
                                    Image(systemName: dest.iconName)
                                        .font(.system(size: 14))
                                        .frame(width: 20)
                                    Text("Slot \(index + 1): \(dest.name)")
                                        .font(.system(size: 12))
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(selectedIndex == index ? Color.accentColor : Color.clear)
                                .foregroundColor(selectedIndex == index ? .white : .primary)
                                .cornerRadius(5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(width: 180, height: 320)
                .background(Color(NSColor.controlBackgroundColor))
                .border(Color(NSColor.gridColor), width: 1)
                .cornerRadius(4)
            }
            
            Divider()
            
            // Right Panel: Edit Selected Destination
            let dest = preferences.destinations[selectedIndex]
            VStack(alignment: .leading, spacing: 12) {
                Text("Edit Slot \(selectedIndex + 1)")
                    .font(.system(size: 13, weight: .bold))
                
                Form {
                    TextField("Destination Name:", text: Binding(
                        get: { dest.name },
                        set: { updateDestination(index: selectedIndex, name: $0) }
                    ))
                    
                    Picker("Destination Type:", selection: Binding(
                        get: { dest.type },
                        set: { updateDestination(index: selectedIndex, type: $0) }
                    )) {
                        ForEach(DestinationType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            TextField("Configuration / Target:", text: Binding(
                                get: { dest.configuration },
                                set: { updateDestination(index: selectedIndex, configuration: $0) }
                            ))
                            
                            if dest.type == .folder {
                                Button("Browse...") {
                                    browsePath(forFolder: true) { path in
                                        updateDestination(index: selectedIndex, configuration: path)
                                    }
                                }
                            } else if dest.type == .application {
                                Button("Browse...") {
                                    browsePath(forFolder: false) { path in
                                        updateDestination(index: selectedIndex, configuration: path)
                                    }
                                }
                            }
                        }
                        
                        Text(helperText(for: dest.type))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Icon Representation:", selection: Binding(
                        get: { dest.iconName },
                        set: { updateDestination(index: selectedIndex, iconName: $0) }
                    )) {
                        ForEach(icons, id: \.self) { icon in
                            HStack {
                                Image(systemName: icon)
                                Text(icon)
                            }.tag(icon)
                        }
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
            // update default icon if type changes
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
    
    private func helperText(for type: DestinationType) -> String {
        switch type {
        case .folder: return "Provide the absolute directory path where files should be copied."
        case .email: return "Optional recipient email address (e.g. hello@world.com) or leave blank to open blank compose window."
        case .messages: return "Optional contact phone number or Apple ID (e.g. +1234567890)."
        case .airDrop: return "No configuration required. Automatically forwards dropped files to AirDrop."
        case .application: return "Absolute path to the macOS application bundle (.app) that should open the files."
        case .url: return "The full website URL to load in the browser (e.g. https://wetransfer.com)."
        case .customScript: return "Absolute path to a shell script (.sh) or direct terminal commands. File paths will be passed as arguments."
        }
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
