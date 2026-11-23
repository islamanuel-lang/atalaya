//
//  Log.swift
//  Atalaya
//
//  Buffer circular de log, hilo seguro. No sale del dispositivo salvo que el
//  usuario comparta el diagnóstico.
//

import Foundation

final class Log {
    static let shared = Log()

    private let lock = NSLock()
    private var lines: [String] = []
    private let limit = 500
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    func add(_ message: String) {
        lock.lock()
        lines.append("[\(formatter.string(from: Date()))] \(message)")
        if lines.count > limit { lines.removeFirst(lines.count - limit) }
        lock.unlock()
    }

    var text: String {
        lock.lock()
        defer { lock.unlock() }
        return lines.joined(separator: "\n")
    }

    func clear() {
        lock.lock()
        lines.removeAll()
        lock.unlock()
    }
}

func log(_ message: String) {
    Log.shared.add(message)
    print(message)
}
