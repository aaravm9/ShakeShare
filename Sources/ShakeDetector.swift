import Cocoa

public class ShakeDetector {
    private struct MousePoint {
        let point: CGPoint
        let timestamp: TimeInterval
    }
    
    private var points: [MousePoint] = []
    private let windowDuration: TimeInterval = 0.4
    private var lastTriggerTime: TimeInterval = 0
    private let triggerCooldown: TimeInterval = 1.5
    
    public var onShakeDetected: (() -> Void)?
    
    public init() {}
    
    public func handleMouseDragged(to location: CGPoint) {
        let now = Date().timeIntervalSince1970
        
        if now - lastTriggerTime < triggerCooldown {
            return
        }
        
        points.append(MousePoint(point: location, timestamp: now))
        points.removeAll { now - $0.timestamp > windowDuration }
        
        if points.count < 6 {
            return
        }
        
        var xReversals = 0
        var yReversals = 0
        
        var lastDx: CGFloat = 0
        var lastDy: CGFloat = 0
        var totalDistance: CGFloat = 0
        
        for i in 1..<points.count {
            let p1 = points[i-1].point
            let p2 = points[i].point
            
            let dx = p2.x - p1.x
            let dy = p2.y - p1.y
            
            totalDistance += sqrt(dx*dx + dy*dy)
            
            if abs(dx) > 3 {
                if lastDx != 0 && (dx > 0) != (lastDx > 0) {
                    xReversals += 1
                }
                lastDx = dx
            }
            
            if abs(dy) > 3 {
                if lastDy != 0 && (dy > 0) != (lastDy > 0) {
                    yReversals += 1
                }
                lastDy = dy
            }
        }
        
        let sensitivity = Preferences.shared.shakeSensitivity
        let requiredReversals = Int(max(2, 6 - (sensitivity / 2.0)))
        let requiredDistance = CGFloat(max(100.0, 500.0 - (sensitivity * 40.0)))
        
        if (xReversals >= requiredReversals || yReversals >= requiredReversals) && totalDistance >= requiredDistance {
            lastTriggerTime = now
            points.removeAll()
            onShakeDetected?()
        }
    }
    
    public func reset() {
        points.removeAll()
    }
}
