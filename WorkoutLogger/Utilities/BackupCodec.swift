import Foundation

/// JSON encoding for `BackupFile` (ISO 8601 dates with fractional seconds, stable key order).
enum BackupCodec {
    enum DecodeError: Error, LocalizedError, Equatable {
        case unsupportedVersion(Int)
        case invalidFile

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let v): "This backup was made by a newer version of the app (format \(v))."
            case .invalidFile: "This file isn't a WorkoutLogger backup."
            }
        }
    }

    /// e.g. "2026-11-16T18:05:12.345Z" (UTC, millisecond precision).
    static let dateStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)

    static func encode(_ file: BackupFile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(dateStyle))
        }
        return try encoder.encode(file)
    }

    static func decode(_ data: Data) throws -> BackupFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            if let date = try? dateStyle.parse(text) { return date }
            if let date = try? Date.ISO8601FormatStyle().parse(text) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date \(text)")
        }
        let file: BackupFile
        do {
            file = try decoder.decode(BackupFile.self, from: data)
        } catch {
            throw DecodeError.invalidFile
        }
        guard file.version <= BackupFile.currentVersion else {
            throw DecodeError.unsupportedVersion(file.version)
        }
        return file
    }
}
