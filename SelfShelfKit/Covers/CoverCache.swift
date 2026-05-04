import Foundation
#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#endif

public actor CoverCache {
    public static let shared = CoverCache()

    private let fm = FileManager.default
    private let directory: URL

    public init() {
        let dir = SharedStore.containerURL.appending(path: "Covers", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.directory = dir
    }

    public nonisolated func localURL(for coverId: Int, size: CoverSize = .medium) -> URL {
        SharedStore.containerURL
            .appending(path: "Covers", directoryHint: .isDirectory)
            .appending(path: "\(coverId)-\(size.rawValue).jpg")
    }

    public nonisolated func existsLocally(coverId: Int, size: CoverSize = .medium) -> Bool {
        FileManager.default.fileExists(atPath: localURL(for: coverId, size: size).path)
    }

    @discardableResult
    public func fetch(coverId: Int, size: CoverSize = .medium) async -> URL? {
        let dest = localURL(for: coverId, size: size)
        if fm.fileExists(atPath: dest.path) { return dest }
        let remote = OpenLibraryClient.coverURL(id: coverId, size: size)
        do {
            let (data, resp) = try await URLSession.shared.data(from: remote)
            guard (resp as? HTTPURLResponse)?.statusCode == 200, data.count > 64 else { return nil }
            try data.write(to: dest, options: .atomic)
            return dest
        } catch {
            return nil
        }
    }

    #if canImport(UIKit)
    public nonisolated func loadImage(coverId: Int, size: CoverSize = .medium) -> UIImage? {
        let url = localURL(for: coverId, size: size)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    #endif

    public func clear() {
        try? fm.removeItem(at: directory)
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func diskSizeBytes() -> Int64 {
        guard let enumerator = fm.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}
