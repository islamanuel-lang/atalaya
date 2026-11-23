//
//  PathScan.swift
//  Atalaya
//
//  Enumeración por inodos (fsgetpath). No lista los padres: recorre números de
//  inodo hasta el baseline y se queda con los hijos directos de cada raíz.
//

import Foundation

enum PathScan {
    private static let identifierAttribute = "com.apple.containermanager.identifier"

    static func baselineInode() -> UInt64? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(".baseline_\(UUID().uuidString)")
        guard FileManager.default.createFile(atPath: url.path, contents: Data("atalaya".utf8)) else {
            return nil
        }
        defer { try? FileManager.default.removeItem(at: url) }
        var info = stat()
        guard stat(url.path, &info) == 0 else { return nil }
        return UInt64(info.st_ino)
    }

    static func identifier(of path: String) -> String? {
        let handle: Int64
        do { handle = try Exploit.consume(path: path) } catch { return nil }
        defer { Exploit.release(handle) }

        var buffer = [CChar](repeating: 0, count: 512)
        let length = getxattr(path, identifierAttribute, &buffer, buffer.count - 1, 0, 0)
        guard length > 0 else { return nil }
        return String(cString: buffer)
    }

    /// Devuelve contenedores con identificador conocido, ordenados por tier.
    static func scan(shouldStop: @escaping () -> Bool,
                     progress: @escaping (String) -> Void) async -> [ScanHit] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let baseline = baselineInode() else {
                    continuation.resume(returning: [])
                    return
                }
                var hits: [ScanHit] = []
                var seen = Set<String>()

                for root in Paths.containerRoots {
                    if shouldStop() { break }
                    progress("Barriendo \(root.split(separator: "/").last ?? "") …")
                    guard let children = pathleak(root, baseline) else { continue }
                    for child in children {
                        if shouldStop() { break }
                        let path = Paths.canonical(child)
                        guard !seen.contains(path) else { continue }
                        seen.insert(path)
                        guard let bundleID = identifier(of: path) else { continue }
                        let tier = Targets.catalog.first { $0.bundleID == bundleID }?.tier ?? 3
                        hits.append(ScanHit(path: path, bundleID: bundleID, tier: tier))
                        if hits.count >= 300 { break }
                    }
                }
                continuation.resume(returning: hits.sorted { $0.tier < $1.tier })
            }
        }
    }
}
