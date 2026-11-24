import SwiftUI
import UniformTypeIdentifiers

struct ProfilesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText = ""
    @State private var selectedGenre: GameGenre?
    @State private var showCreateSheet = false
    @State private var editingProfile: GameProfile?
    @State private var exportingProfile: GameProfile?
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    @State private var showSettings = false

    private var filteredProfiles: [GameProfile] {
        store.profiles.filter { profile in
            let matchesGenre = selectedGenre == nil || profile.genre == selectedGenre
            let matchesSearch = searchText.isEmpty
                || profile.name.localizedCaseInsensitiveContains(searchText)
                || profile.gameTitle.localizedCaseInsensitiveContains(searchText)
            return matchesGenre && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            List {
                genreFilterSection

                Section("Profiles (\(filteredProfiles.count))") {
                    ForEach(filteredProfiles) { profile in
                        profileRow(profile)
                    }
                    .onDelete { offsets in
                        for idx in offsets {
                            store.deleteProfile(filteredProfiles[idx].id)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search profiles or games")
            .navigationTitle(store.t("profiles.title"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label(store.t("profiles.import"), systemImage: "square.and.arrow.down")
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label(store.t("profiles.new"), systemImage: "plus.circle.fill")
                    }

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showCreateSheet) {
                ProfileEditorSheet(profile: nil) { created in
                    store.addProfile(created)
                }
            }
            .sheet(item: $editingProfile) { profile in
                ProfileEditorSheet(profile: profile) { updated in
                    store.updateProfile(updated)
                }
            }
            .fileExporter(
                isPresented: $showFileExporter,
                document: exportingProfile.map { ProfileExportDocument(profile: $0) },
                contentType: .json,
                defaultFilename: (exportingProfile?.name ?? "TouchForgeProfile").replacingOccurrences(of: " ", with: "_")
            ) { result in
                if case .success = result {
                    store.showToast("Profile exported successfully")
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json, .touchForgeProfile]
            ) { result in
                switch result {
                case .success(let url):
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url) {
                        do {
                            _ = try store.importProfile(from: data)
                        } catch {
                            store.showToast("Invalid profile JSON file")
                        }
                    }
                case .failure:
                    store.showToast("Import cancelled")
                }
            }
        }
    }

    private var genreFilterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: "All", isSelected: selectedGenre == nil) {
                        selectedGenre = nil
                    }
                    ForEach(GameGenre.allCases) { genre in
                        filterChip(title: store.t(genre.displayNameKey), isSelected: selectedGenre == genre) {
                            selectedGenre = genre
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        }
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? store.settings.accentTheme.color : Color(.tertiarySystemFill),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func profileRow(_ profile: GameProfile) -> some View {
        let isActive = profile.id == store.activeProfile.id

        return HStack(spacing: 12) {
            Image(systemName: profile.genre.systemImage)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(
                    (isActive ? store.settings.accentTheme.color : Color.gray).gradient,
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.name)
                        .font(.headline)
                    if isActive {
                        Text(store.t("profiles.active"))
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.18), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
                Text("\(profile.gameTitle) • \(profile.controls.count) controls")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                if !isActive {
                    Button {
                        store.selectProfile(profile.id)
                    } label: {
                        Label(store.t("profiles.activate"), systemImage: "checkmark.circle")
                    }
                }
                Button {
                    editingProfile = profile
                } label: {
                    Label("Edit Info", systemImage: "pencil")
                }
                Button {
                    store.duplicateProfile(profile)
                } label: {
                    Label(store.t("profiles.duplicate"), systemImage: "doc.on.doc")
                }
                Button {
                    exportingProfile = profile
                    showFileExporter = true
                } label: {
                    Label(store.t("profiles.export"), systemImage: "square.and.arrow.up")
                }
                Divider()
                Button(role: .destructive) {
                    store.deleteProfile(profile.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectProfile(profile.id)
        }
    }
}
