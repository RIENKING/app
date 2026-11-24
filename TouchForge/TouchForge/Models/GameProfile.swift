import Foundation

enum GameGenre: String, Codable, CaseIterable, Identifiable {
    case fps
    case battleRoyale
    case moba
    case actionRPG
    case racing
    case custom

    var id: String { rawValue }

    var displayNameKey: String {
        switch self {
        case .fps: return "genre.fps"
        case .battleRoyale: return "genre.battleRoyale"
        case .moba: return "genre.moba"
        case .actionRPG: return "genre.actionRPG"
        case .racing: return "genre.racing"
        case .custom: return "genre.custom"
        }
    }

    var systemImage: String {
        switch self {
        case .fps: return "scope"
        case .battleRoyale: return "flame.fill"
        case .moba: return "shield.lefthalf.filled"
        case .actionRPG: return "sparkles"
        case .racing: return "flag.checkered"
        case .custom: return "gamecontroller.fill"
        }
    }
}

struct GameProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var gameTitle: String
    var genre: GameGenre
    var notes: String
    var controls: [VirtualTouchControl]
    var crosshair: CrosshairConfig
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        gameTitle: String,
        genre: GameGenre = .fps,
        notes: String = "",
        controls: [VirtualTouchControl] = [],
        crosshair: CrosshairConfig = CrosshairConfig(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.gameTitle = gameTitle
        self.genre = genre
        self.notes = notes
        self.controls = controls
        self.crosshair = crosshair
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func duplicated() -> GameProfile {
        let now = Date()
        var copy = self
        copy.id = UUID()
        copy.name = "\(name) (Copy)"
        copy.controls = controls.map { ctrl in
            var c = ctrl
            c.id = UUID()
            return c
        }
        copy.createdAt = now
        copy.updatedAt = now
        return copy
    }
}
