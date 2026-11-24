import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showBackupExporter = false
    @State private var showBackupImporter = false
    @State private var showResetConfirm = false

    private var settingsBinding: Binding<AppSettings> {
        Binding(
            get: { store.settings },
            set: {
                store.settings = $0
                store.save()
            }
        )
    }

    var body: some View {
        Form {
            Section(store.t("settings.appearance")) {
                Picker(store.t("settings.appearance"), selection: settingsBinding.appearance) {
                    ForEach(AppAppearance.allCases) { mode in
                        Text(store.t(mode.displayNameKey)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Picker(store.t("settings.language"), selection: settingsBinding.language) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeName).tag(lang)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(store.t("settings.accent"))
                        .font(.subheadline)
                    HStack(spacing: 14) {
                        ForEach(AccentTheme.allCases) { theme in
                            Button {
                                var updated = store.settings
                                updated.accentTheme = theme
                                store.settings = updated
                                store.save()
                            } label: {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                            .opacity(store.settings.accentTheme == theme ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Section(store.t("settings.controls")) {
                Toggle(store.t("settings.haptics"), isOn: settingsBinding.hapticsEnabled)
                Toggle(store.t("settings.snapGrid"), isOn: settingsBinding.snapToGrid)
                if store.settings.snapToGrid {
                    Stepper("Grid Step: \(store.settings.gridSize) pt", value: settingsBinding.gridSize, in: 8...32, step: 4)
                }
                Toggle(store.t("settings.showCoords"), isOn: settingsBinding.showCoordinatesOverlay)
                Toggle(store.t("settings.showRipples"), isOn: settingsBinding.showTestRipples)
            }

            Section("Shortcuts, Siri & Action Button") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("App Intents Enabled", systemImage: "command.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text("Open Apple's Shortcuts app and search for 'TouchForge' to assign Switch Profile, Run Macro, or Stop Macro to your iPhone Action Button, Back Tap, or Siri.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section("Hardware & Official iOS Limits") {
                NavigationLink {
                    HardwareBridgeView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.t("settings.hardware"))
                            Text(store.bleBridge.connectedDeviceName ?? store.bleBridge.connectionState.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.blue)
                    }
                }

                NavigationLink {
                    CapabilitiesGuideView()
                } label: {
                    Label(store.t("settings.capabilities"), systemImage: "checkmark.shield.fill")
                }
            }

            Section(store.t("settings.backup")) {
                Button {
                    showBackupExporter = true
                } label: {
                    Label(store.t("settings.exportBackup"), systemImage: "externaldrive.badge.plus")
                }

                Button {
                    showBackupImporter = true
                } label: {
                    Label(store.t("settings.importBackup"), systemImage: "arrow.clockwise.icloud")
                }

                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label(store.t("settings.resetDefaults"), systemImage: "arrow.counterclockwise")
                }
            }

            Section("About TouchForge") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Standard iOS)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Account Required")
                    Spacer()
                    Text("None (100% Local & Private)")
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle(store.t("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showBackupExporter,
            document: FullBackupDocument(payload: store.makeBackupPayload()),
            contentType: .json,
            defaultFilename: "TouchForge_Backup"
        ) { result in
            if case .success = result {
                store.showToast("Full backup exported")
            }
        }
        .fileImporter(
            isPresented: $showBackupImporter,
            allowedContentTypes: [.json, .touchForgeBackup]
        ) { result in
            switch result {
            case .success(let url):
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url),
                   let restored = try? PersistenceService.shared.decodeJSON(TouchForgeBackupPayload.self, from: data) {
                    store.restoreBackup(restored)
                } else {
                    store.showToast("Invalid backup file")
                }
            case .failure:
                store.showToast("Restore cancelled")
            }
        }
        .confirmationDialog(
            "Reset all profiles, macros, and settings to starter defaults?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                store.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
