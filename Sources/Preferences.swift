import Foundation

public enum ThemeType: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case glass = "glass"
    case matte = "matte"
}

public class Preferences: ObservableObject {
    public static let shared = Preferences()
    
    @Published public var shakeSensitivity: Double {
        didSet { UserDefaults.standard.set(shakeSensitivity, forKey: "shakeSensitivity") }
    }
    
    @Published public var activationDelay: Double {
        didSet { UserDefaults.standard.set(activationDelay, forKey: "activationDelay") }
    }
    
    @Published public var autoClose: Bool {
        didSet { UserDefaults.standard.set(autoClose, forKey: "autoClose") }
    }
    
    @Published public var failureHandling: String {
        didSet { UserDefaults.standard.set(failureHandling, forKey: "failureHandling") }
    }
    
    @Published public var appLaunchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(appLaunchAtLogin, forKey: "appLaunchAtLogin")
            toggleLaunchAtLogin(appLaunchAtLogin)
        }
    }
    
    @Published public var multiMonitorPreference: String {
        didSet { UserDefaults.standard.set(multiMonitorPreference, forKey: "multiMonitorPreference") }
    }
    
    @Published public var theme: ThemeType {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: "theme") }
    }
    
    @Published public var destinations: [Destination] {
        didSet {
            if let encoded = try? JSONEncoder().encode(destinations) {
                UserDefaults.standard.set(encoded, forKey: "destinations")
            }
        }
    }
    
    @Published public var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    
    private init() {
        UserDefaults.standard.register(defaults: [
            "shakeSensitivity": 5.0,
            "activationDelay": 0.1,
            "autoClose": true,
            "failureHandling": "smart",
            "appLaunchAtLogin": false,
            "multiMonitorPreference": "mouseScreen",
            "theme": "glass",
            "hasCompletedOnboarding": false
        ])
        
        self.shakeSensitivity = UserDefaults.standard.double(forKey: "shakeSensitivity")
        self.activationDelay = UserDefaults.standard.double(forKey: "activationDelay")
        self.autoClose = UserDefaults.standard.bool(forKey: "autoClose")
        self.failureHandling = UserDefaults.standard.string(forKey: "failureHandling") ?? "smart"
        self.appLaunchAtLogin = UserDefaults.standard.bool(forKey: "appLaunchAtLogin")
        self.multiMonitorPreference = UserDefaults.standard.string(forKey: "multiMonitorPreference") ?? "mouseScreen"
        self.theme = ThemeType(rawValue: UserDefaults.standard.string(forKey: "theme") ?? "glass") ?? .glass
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        if let data = UserDefaults.standard.data(forKey: "destinations"),
           let decoded = try? JSONDecoder().decode([Destination].self, from: data),
           decoded.count == 8 {
            self.destinations = decoded
        } else {
            let homeDir = NSHomeDirectory()
            let defaults: [Destination] = [
                Destination(name: "Desktop", type: .folder, iconName: "desktopcomputer", configuration: homeDir + "/Desktop"),
                Destination(name: "Documents", type: .folder, iconName: "doc.text", configuration: homeDir + "/Documents"),
                Destination(name: "Downloads", type: .folder, iconName: "arrow.down.circle", configuration: homeDir + "/Downloads"),
                Destination(name: "AirDrop", type: .airDrop, iconName: "wifi", configuration: ""),
                Destination(name: "Mail Compose", type: .email, iconName: "envelope", configuration: ""),
                Destination(name: "iMessage Compose", type: .messages, iconName: "message", configuration: ""),
                Destination(name: "Web Share", type: .url, iconName: "globe", configuration: "https://wetransfer.com"),
                Destination(name: "Terminal Log", type: .customScript, iconName: "terminal", configuration: "echo 'Sharing files:'")
            ]
            self.destinations = defaults
            if let encoded = try? JSONEncoder().encode(defaults) {
                UserDefaults.standard.set(encoded, forKey: "destinations")
            }
        }
    }
    
    private func toggleLaunchAtLogin(_ enabled: Bool) {
        // A placeholder for launch-at-login integration.
        // High-level SMAppService controls require App Store sandboxing, but for ad-hoc apps it's usually handled manually or via LaunchAgents.
    }
}
