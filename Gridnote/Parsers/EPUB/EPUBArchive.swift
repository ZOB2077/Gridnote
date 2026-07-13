import Compression
import Foundation

struct EPUBArchive {
    private struct Entry {
        let method: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localHeaderOffset: Int
    }

    private let data: Data
    private let entries: [String: Entry]

    init(data: Data) throws {
        self.data = data
        self.entries = try Self.readDirectory(from: data)
    }

    func contains(_ path: String) -> Bool {
        entries[path] != nil
    }

    func data(at path: String) throws -> Data {
        guard let entry = entries[path] else {
            throw GridnoteError.parseFailed("EPUB entry is missing: \(path)")
        }
        let offset = entry.localHeaderOffset
        guard data.uint32(at: offset) == 0x04034b50 else {
            throw GridnoteError.parseFailed("Invalid EPUB local file header")
        }
        let nameLength = Int(data.uint16(at: offset + 26))
        let extraLength = Int(data.uint16(at: offset + 28))
        let start = offset + 30 + nameLength + extraLength
        guard start >= 0, start + entry.compressedSize <= data.count else {
            throw GridnoteError.parseFailed("Truncated EPUB entry")
        }
        let payload = data.subdata(in: start..<(start + entry.compressedSize))
        switch entry.method {
        case 0:
            return payload
        case 8:
            return try Self.inflate(payload, expectedSize: entry.uncompressedSize)
        default:
            throw GridnoteError.parseFailed("Unsupported EPUB compression method")
        }
    }

    private static func readDirectory(from data: Data) throws -> [String: Entry] {
        guard data.count >= 22 else { throw GridnoteError.parseFailed("Invalid EPUB archive") }
        let lowerBound = max(0, data.count - 65_557)
        var endOffset: Int?
        for offset in stride(from: data.count - 22, through: lowerBound, by: -1) {
            if data.uint32(at: offset) == 0x06054b50 {
                endOffset = offset
                break
            }
        }
        guard let endOffset else { throw GridnoteError.parseFailed("Invalid EPUB central directory") }
        let count = Int(data.uint16(at: endOffset + 10))
        var cursor = Int(data.uint32(at: endOffset + 16))
        var result: [String: Entry] = [:]

        for _ in 0..<count {
            guard cursor + 46 <= data.count, data.uint32(at: cursor) == 0x02014b50 else {
                throw GridnoteError.parseFailed("Corrupted EPUB central directory")
            }
            let nameLength = Int(data.uint16(at: cursor + 28))
            let extraLength = Int(data.uint16(at: cursor + 30))
            let commentLength = Int(data.uint16(at: cursor + 32))
            let nameStart = cursor + 46
            guard nameStart + nameLength <= data.count,
                  let name = String(data: data.subdata(in: nameStart..<(nameStart + nameLength)), encoding: .utf8) else {
                throw GridnoteError.parseFailed("Invalid EPUB entry name")
            }
            result[name] = Entry(
                method: data.uint16(at: cursor + 10),
                compressedSize: Int(data.uint32(at: cursor + 20)),
                uncompressedSize: Int(data.uint32(at: cursor + 24)),
                localHeaderOffset: Int(data.uint32(at: cursor + 42))
            )
            cursor = nameStart + nameLength + extraLength + commentLength
        }
        return result
    }

    private static func inflate(_ input: Data, expectedSize: Int) throws -> Data {
        var output = Data(count: max(expectedSize, 1))
        let decoded = output.withUnsafeMutableBytes { destination in
            input.withUnsafeBytes { source in
                compression_decode_buffer(
                    destination.bindMemory(to: UInt8.self).baseAddress!, destination.count,
                    source.bindMemory(to: UInt8.self).baseAddress!, source.count,
                    nil, COMPRESSION_ZLIB
                )
            }
        }
        guard decoded > 0 else { throw GridnoteError.parseFailed("Unable to decompress EPUB entry") }
        output.count = decoded
        return output
    }
}

private extension Data {
    func uint16(at offset: Int) -> UInt16 {
        guard offset >= 0, offset + 2 <= count else { return 0 }
        return withUnsafeBytes { rawBytes in
            let bytes = rawBytes.bindMemory(to: UInt8.self)
            let low = UInt16(bytes[offset])
            let high = UInt16(bytes[offset + 1]) << 8
            return low | high
        }
    }

    func uint32(at offset: Int) -> UInt32 {
        guard offset >= 0, offset + 4 <= count else { return 0 }
        return withUnsafeBytes { rawBytes in
            let bytes = rawBytes.bindMemory(to: UInt8.self)
            let byte0 = UInt32(bytes[offset])
            let byte1 = UInt32(bytes[offset + 1]) << 8
            let byte2 = UInt32(bytes[offset + 2]) << 16
            let byte3 = UInt32(bytes[offset + 3]) << 24
            return byte0 | byte1 | byte2 | byte3
        }
    }
}
