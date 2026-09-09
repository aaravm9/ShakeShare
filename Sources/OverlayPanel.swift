import Cocoa
import SwiftUI

public class OverlayViewModel: ObservableObject {
    @Published public var selectedIndex: Int? = nil
    @Published public var draggedFilesCount: Int = 0
    @Published public var mouseLocation: CGPoint = .zero
}

public class OverlayPanel: NSPanel {
    public let viewModel = OverlayViewModel()
    private let fileURLs: [URL]
    private var dragMonitor: Any?
    private var upMonitor: Any?
    private var keyMonitor: Any?
    private let screenFrame: CGRect

    public init(screen: NSScreen, fileURLs: [URL]) {
        self.fileURLs = fileURLs
        self.screenFrame = screen.frame

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        self.isReleasedWhenClosed = false
        self.ignoresMouseEvents = true   // transparent to mouse clicks — we track globally

        viewModel.draggedFilesCount = fileURLs.count

        // Host the SwiftUI WheelView
        let wheelView = WheelView()
            .environmentObject(viewModel)
            .environmentObject(Preferences.shared)
        let hostingView = NSHostingView(rootView: wheelView)
        hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
        self.contentView = hostingView

        startTracking()
    }

    deinit {
        stopTracking()
    }

    public override var canBecomeKey: Bool { false }

    // MARK: - Mouse Tracking

    private func startTracking() {
        // Track dragged & moved positions to highlight segments
        dragMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDragged, .mouseMoved]
        ) { [weak self] event in
            self?.updateSelection(at: NSEvent.mouseLocation)
        }

        // When user releases mouse → execute selected destination
        upMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .leftMouseUp
        ) { [weak self] _ in
            self?.commitSelection()
        }

        // ESC key → cancel
        keyMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: .keyDown
        ) { [weak self] event in
            if event.keyCode == 53 { // ESC
                DispatchQueue.main.async { AppDelegate.shared?.closeOverlay() }
            }
        }

        // Seed initial position
        updateSelection(at: NSEvent.mouseLocation)
    }

    private func stopTracking() {
        [dragMonitor, upMonitor, keyMonitor].compactMap { $0 }.forEach {
            NSEvent.removeMonitor($0)
        }
        dragMonitor = nil
        upMonitor = nil
        keyMonitor = nil
    }

    private func updateSelection(at globalLocation: CGPoint) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.viewModel.mouseLocation = globalLocation

            // Convert global screen coords to panel-local coords
            let localX = globalLocation.x - self.screenFrame.minX
            let localY = globalLocation.y - self.screenFrame.minY

            let center = CGPoint(x: self.screenFrame.width / 2, y: self.screenFrame.height / 2)
            let dx = localX - center.x
            let dy = localY - center.y
            let distance = sqrt(dx * dx + dy * dy)

            let innerRadius: CGFloat = 65
            let outerRadius: CGFloat = 210

            if distance >= innerRadius && distance <= outerRadius {
                var angle = atan2(dy, dx) * 180 / .pi
                if angle < 0 { angle += 360 }
                let cwAngle = (360 - angle)
                let segment = Int((cwAngle + 22.5) / 45.0) % 8
                self.viewModel.selectedIndex = segment
            } else {
                self.viewModel.selectedIndex = nil
            }
        }
    }

    private func commitSelection() {
        let selectedIndex = viewModel.selectedIndex
        let files = fileURLs

        DispatchQueue.main.async {
            AppDelegate.shared?.closeOverlay()

            guard let idx = selectedIndex, idx >= 0, idx < 8 else { return }
            let destination = Preferences.shared.destinations[idx]

            DispatchQueue.global(qos: .userInitiated).async {
                destination.execute(with: files) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            NSSound(named: "Glass")?.play()
                        case .failure(let error):
                            NSSound(named: "Basso")?.play()
                            let alert = NSAlert()
                            alert.messageText = "Sharing Failed"
                            alert.informativeText = "Could not share to \(destination.name).\n\n\(error.localizedDescription)"
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "OK")
                            if Preferences.shared.failureHandling == "smart" {
                                alert.addButton(withTitle: "Open Preferences")
                            }
                            let response = alert.runModal()
                            if response == .alertSecondButtonReturn {
                                AppDelegate.shared?.showPreferences()
                            }
                        }
                    }
                }
            }
        }
    }
}
