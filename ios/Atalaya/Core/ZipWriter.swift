//
//  ZipWriter.swift
//  Atalaya
//
//  ZIP mínimo en método store (sin compresión), suficiente para empaquetar
//  ficheros de texto y capturas sin dependencias externas.
//

import Foundation

final class ZipWriter {
    private struct Entry {
        let name: Data
        let crc: UInt32
        let size: UInt32
        let offset: UInt32
    }

    private let handle: FileHandle
    private var entries: [Entry] = []
    private var offset: UInt32 = 0
    private let url: URL

    private static let crcTable: [UInt32] = (0...255).map { index in
        var value = UInt32(index)
        for _ in 0..<8 {
            value = (value & 1) == 1 ? (0xEDB88320 ^ (value >> 1)) : (value >> 1)
        }
        return value
    }

    init(url: URL) throws {
        self.url = url
        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: url) else {
            throw CocoaError(.fileWriteUnknown)
        }
        self.handle = handle
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
        }
        return crc ^ 0xFFFFFFFF
    }

    private func write<T: FixedWidthInteger>(_ value: T) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { handle.write(Data($0)) }
    }

    func add(name: String, data: Data) throws {
        let nameData = Data(name.utf8)
        guard nameData.count < 0xFFFF, data.count < Int(UInt32.max) else { return }
        let crc = Self.crc32(data)

        write(UInt32(0x04034b50))
        write(UInt16(20))
        write(UInt16(0x0800)) // nombres UTF-8
        write(UInt16(0))      // store
        write(UInt16(0))      // hora
        write(UInt16(0))      // fecha
        write(crc)
        write(UInt32(data.count))
        write(UInt32(data.count))
        write(UInt16(nameData.count))
        write(UInt16(0))
        handle.write(nameData)
        handle.write(data)

        entries.append(Entry(name: nameData, crc: crc,
                             size: UInt32(data.count), offset: offset))
        offset += UInt32(30 + nameData.count + data.count)
    }

    func finish() throws {
        let centralOffset = offset
        for entry in entries {
            write(UInt32(0x02014b50))
            write(UInt16(20))
            write(UInt16(20))
            write(UInt16(0x0800))
            write(UInt16(0))
            write(UInt16(0))
            write(UInt16(0))
            write(entry.crc)
            write(entry.size)
            write(entry.size)
            write(UInt16(entry.name.count))
            write(UInt16(0))
            write(UInt16(0))
            write(UInt16(0))
            write(UInt16(0))
            write(UInt32(0))
            write(entry.offset)
            handle.write(entry.name)
            offset += UInt32(46 + entry.name.count)
        }
        let centralSize = offset - centralOffset
        write(UInt32(0x06054b50))
        write(UInt16(0))
        write(UInt16(0))
        write(UInt16(entries.count))
        write(UInt16(entries.count))
        write(centralSize)
        write(centralOffset)
        write(UInt16(0))
        try handle.close()
    }
}
