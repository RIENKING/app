import SwiftUI

struct ProfileEditorSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let existingProfile: GameProfile?
    let onSave: (GameProfile) -> Void

    @State private var name: String = ""
    @State private var gameTitle: String = ""
    @State private var genre: GameGenre = .fps
    @State private var notes: String = ""

    init(profile: GameProfile?, onSave: @escaping (GameProfile) -> Void) {
        self.existingProfile = profile
        self.onSave = onSave
        _name = State(initialValue: profile?.name ?? "")
        _gameTitle = State(initialValue: profile?.gameTitle ?? "")
        _genre = State(initialValue: profile?.genre ?? .fps)
        _notes = State(initialValue: profile?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Information") {
                    TextField("Profile Name (e.g., Ranked Claw)", text: $name)
                    TextField("Game Title (e.g., Tactical Arena)", text: $gameTitle)
                    Picker("Game Genre", selection: $genre) {
                        ForEach(GameGenre.allCases) { item in
                            Label(store.t(item.displayNameKey), systemImage: item.systemImage).tag(item)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(existingProfile == nil ? "New Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        let cleanGame = gameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if var updated = existingProfile {
                            updated.name = cleanName.isEmpty ? updated.name : cleanName
                            updated.gameTitle = cleanGame.isEmpty ? updated.gameTitle : cleanGame
                            updated.genre = genre
                            updated.notes = notes
                            onSave(updated)
                        } else {
                            let created = GameProfile(
                                name: cleanName.isEmpty ? "Custom Profile" : cleanName,
                                gameTitle: cleanGame.isEmpty ? "Custom Game" : cleanGame,
                                genre: genre,
                                notes: notes
                            )
                            onSave(created)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
