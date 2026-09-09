import Cocoa
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    public static var shared: AppDelegate?
    
    public var statusItem: NSStatusItem!
    public var overlayPanel: OverlayPanel?
    public let shakeDetector = ShakeDetector()
    public var globalMonitor: Any?
    public var localMonitor: Any?
    
    public var preferencesWindow: NSWindow?
    public var setupWizardWindow: NSWindow?
    public var permissionWindow: NSWindow?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        setupMenuBar()
        
        shakeDetector.onShakeDetected = { [weak self] in
            self?.triggerOverlay()
        }
        
        startMonitoring()
        
        // Show Setup Wizard on first run
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if !Preferences.shared.hasCompletedOnboarding {
                self?.showSetupWizard()
            }
        }
    }
    
    public func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.up.forward.app.fill", accessibilityDescription: "ShakeShare")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "ShakeShare Active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Setup Wizard...", action: #selector(showSetupWizard), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc public func quitApp() {
        NSApp.terminate(nil)
    }
    
    public func startMonitoring() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handleMouseEvent(event)
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            self?.handleMouseEvent(event)
            return event
        }
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        if event.type == .leftMouseDragged {
            shakeDetector.handleMouseDragged(to: NSEvent.mouseLocation)
        } else if event.type == .leftMouseUp {
            shakeDetector.reset()
        }
    }
    
    public func triggerOverlay() {
        if overlayPanel != nil { return }

        // Stage 1: Try the live drag pasteboard (populated during an active drag-and-drop gesture)
        let dragPboard = NSPasteboard(name: .drag)
        let dragURLs = (dragPboard.readObjects(forClasses: [NSURL.self], options: nil) as? [NSURL])?.map { $0 as URL } ?? []

        if !dragURLs.isEmpty {
            // We have an active drag session — use those files directly
            presentOverlay(with: dragURLs)
        } else {
            // Stage 2: No active drag — user selected files in Finder and shook.
            // Query Finder's current selection via AppleScript.
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let finderURLs = self?.finderSelectionURLs() ?? []
                DispatchQueue.main.async {
                    guard !finderURLs.isEmpty else { return }
                    self?.presentOverlay(with: finderURLs)
                }
            }
        }
    }

    /// Uses AppleScript to fetch the list of items currently selected in Finder.
    private func finderSelectionURLs() -> [URL] {
        let script = """
        tell application "Finder"
            set theSelection to selection as alias list
            set thePaths to {}
            repeat with anItem in theSelection
                set end of thePaths to POSIX path of anItem
            end repeat
            return thePaths
        end tell
        """
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return [] }
        let result = appleScript.executeAndReturnError(&error)
        guard error == nil else { return [] }

        // Result is a list descriptor — iterate its items
        var urls: [URL] = []
        if result.descriptorType == typeAEList {
            for i in 1...max(1, result.numberOfItems) {
                if result.numberOfItems == 0 { break }
                if let item = result.atIndex(i), let posixPath = item.stringValue {
                    urls.append(URL(fileURLWithPath: posixPath))
                }
            }
        } else if let singlePath = result.stringValue, !singlePath.isEmpty {
            urls.append(URL(fileURLWithPath: singlePath))
        }
        return urls
    }

    private func presentOverlay(with fileURLs: [URL]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.overlayPanel == nil else { return }
            let mouseLocation = NSEvent.mouseLocation
            let activeScreen = NSScreen.screens.first {
                NSMouseInRect(mouseLocation, $0.frame, false)
            } ?? NSScreen.main ?? NSScreen.screens.first
            guard let screen = activeScreen else { return }

            let panel = OverlayPanel(screen: screen, fileURLs: fileURLs)
            self.overlayPanel = panel
            panel.orderFrontRegardless()
        }
    }
    
    public func closeOverlay() {
        overlayPanel?.close()
        overlayPanel = nil
    }
    
    @objc public func showPreferences() {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let view = PreferencesView()
            .environmentObject(Preferences.shared)
        let hostingController = NSHostingController(rootView: view)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "ShakeShare Preferences"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc public func showSetupWizard() {
        if let window = setupWizardWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let view = SetupWizardView(onComplete: { [weak self] in
            self?.setupWizardWindow?.close()
            self?.setupWizardWindow = nil
            Preferences.shared.hasCompletedOnboarding = true
        })
        let hostingController = NSHostingController(rootView: view)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to ShakeShare"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        setupWizardWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func showPermissionGuidance() {
        if let window = permissionWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let view = PermissionGuidanceView(onGrantClicked: { [weak self] in
            self?.openSystemAccessibilitySettings()
        }, onCloseClicked: { [weak self] in
            self?.permissionWindow?.close()
            self?.permissionWindow = nil
        })
        let hostingController = NSHostingController(rootView: view)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Accessibility Permission Required"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        
        permissionWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func checkAccessibilityPermissions(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    public func openSystemAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

extension AppDelegate: NSWindowDelegate {
    public func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window == preferencesWindow {
                preferencesWindow = nil
            } else if window == setupWizardWindow {
                setupWizardWindow = nil
            } else if window == permissionWindow {
                permissionWindow = nil
            }
        }
    }
}
