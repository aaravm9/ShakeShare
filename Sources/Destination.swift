import Cocoa

public enum DestinationType: String, Codable, CaseIterable {
    case folder = "Folder"
    case email = "Email"
    case messages = "Messages"
    case airDrop = "AirDrop"
    case application = "Application"
    case url = "Website"
    case customScript = "Custom Script"
}

public struct Destination: Identifiable, Codable {
    public var id: UUID
    public var name: String
    public var type: DestinationType
    public var iconName: String
    public var configuration: String
    
    public init(id: UUID = UUID(), name: String, type: DestinationType, iconName: String, configuration: String) {
        self.id = id
        self.name = name
        self.type = type
        self.iconName = iconName
        self.configuration = configuration
    }
}

extension Destination {
    public func execute(with fileURLs: [URL], completion: @escaping (Result<Void, Error>) -> Void) {
        switch type {
        case .folder:
            let fileManager = FileManager.default
            let destFolderURL = URL(fileURLWithPath: configuration.expandingTildeInPath)
            
            // Check if folder exists
            var isDir: ObjCBool = false
            if !fileManager.fileExists(atPath: destFolderURL.path, isDirectory: &isDir) || !isDir.boolValue {
                completion(.failure(NSError(domain: "ShakeShare", code: 101, userInfo: [NSLocalizedDescriptionKey: "Destination folder does not exist: \(configuration)"])))
                return
            }
            
            do {
                for fileURL in fileURLs {
                    let destFileURL = destFolderURL.appendingPathComponent(fileURL.lastPathComponent)
                    if fileManager.fileExists(atPath: destFileURL.path) {
                        // If file already exists, append unique timestamp
                        let nameWithoutExtension = fileURL.deletingPathExtension().lastPathComponent
                        let fileExtension = fileURL.pathExtension
                        let timestamp = Int(Date().timeIntervalSince1970)
                        let newName = "\(nameWithoutExtension)_\(timestamp).\(fileExtension)"
                        let uniqueDestURL = destFolderURL.appendingPathComponent(newName)
                        try fileManager.copyItem(at: fileURL, to: uniqueDestURL)
                    } else {
                        try fileManager.copyItem(at: fileURL, to: destFileURL)
                    }
                }
                // Reveal in Finder
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: destFolderURL.path)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
            
        case .email:
            guard let service = NSSharingService(named: .composeEmail) else {
                completion(.failure(NSError(domain: "ShakeShare", code: 102, userInfo: [NSLocalizedDescriptionKey: "Mail sharing service not available."])))
                return
            }
            if !configuration.isEmpty {
                service.recipients = [configuration]
            }
            DispatchQueue.main.async {
                service.perform(withItems: fileURLs)
                completion(.success(()))
            }
            
        case .messages:
            guard let service = NSSharingService(named: .composeMessage) else {
                completion(.failure(NSError(domain: "ShakeShare", code: 103, userInfo: [NSLocalizedDescriptionKey: "Messages sharing service not available."])))
                return
            }
            if !configuration.isEmpty {
                service.recipients = [configuration]
            }
            DispatchQueue.main.async {
                service.perform(withItems: fileURLs)
                completion(.success(()))
            }
            
        case .airDrop:
            guard let service = NSSharingService(named: .sendViaAirDrop) else {
                completion(.failure(NSError(domain: "ShakeShare", code: 104, userInfo: [NSLocalizedDescriptionKey: "AirDrop sharing service not available."])))
                return
            }
            DispatchQueue.main.async {
                service.perform(withItems: fileURLs)
                completion(.success(()))
            }
            
        case .application:
            let appURL = URL(fileURLWithPath: configuration.expandingTildeInPath)
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open(fileURLs, withApplicationAt: appURL, configuration: config) { _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
            
        case .url:
            guard let url = URL(string: configuration) else {
                completion(.failure(NSError(domain: "ShakeShare", code: 105, userInfo: [NSLocalizedDescriptionKey: "Invalid URL string: \(configuration)"])))
                return
            }
            NSWorkspace.shared.open(url)
            completion(.success(()))
            
        case .customScript:
            let scriptPath = configuration.expandingTildeInPath
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            
            // Format file paths as space-separated quoted arguments
            let escapedPaths = fileURLs.map { "'\($0.path)'" }.joined(separator: " ")
            process.arguments = ["-c", "\(scriptPath) \(escapedPaths)"]
            
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    completion(.success(()))
                } else {
                    completion(.failure(NSError(domain: "ShakeShare", code: 106, userInfo: [NSLocalizedDescriptionKey: "Script exited with error code \(process.terminationStatus)"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

extension String {
    public var expandingTildeInPath: String {
        return (self as NSString).expandingTildeInPath
    }
}
