import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let touchForgeProfile = UTType(exportedAs: "com.touchforge.ios.profile", conformingTo: .json)
    static let touchForgeBackup = UTType(exportedAs: "com.touchforge.ios.backup", conformingTo: .json)
}

struct TouchForgeBackupPayload: Codable, Equatable {
    var schemaVersion: Int = 1
    var exportedAt: Date = Date()
    var profiles: [GameProfile]
    var macros: [MacroProfile]
    var settings: AppSettings
    var activeProfileId: UUID?
}

struct ProfileExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .touchForgeProfile] }

    var profile: GameProfile

    init(profile: GameProfile) {
        self.profile = profile
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.profile = try decoder.decode(GameProfile.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)
        return FileWrapper(regularFileWithContents: data)
    }
}

struct FullBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .touchForgeBackup] }

    var payload: TouchForgeBackupPayload

    init(payload: TouchForgeBackupPayload) {
        self.payload = payload
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.payload = try decoder.decode(TouchForgeBackupPayload.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        return FileWrapper(regularFileWithContents: data)
    }
}
