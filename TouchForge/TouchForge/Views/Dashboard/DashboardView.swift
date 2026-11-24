import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showSettings = false
    @State private var showCapabilities = false
    @State private var showHardwareBridge = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    activeProfileCard
                    quickActionsGrid
                    pipHUDCard
                    hardwareStatusCard
                    quickMacrosSection
                    iosCapabilitiesBanner
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(store.t("dashboard.title"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(store.t("settings.title"))
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(isPresented: $showCapabilities) {
                CapabilitiesGuideView()
            }
            .navigationDestination(isPresented: $showHardwareBridge) {
                HardwareBridgeView()
            }
        }
    }

    private var activeProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(store.t("dashboard.activeProfile"), systemImage: store.activeProfile.genre.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Menu {
                    ForEach(store.profiles) { profile in
                        Button {
                            store.selectProfile(profile.id)
                        } label: {
                            if profile.id == store.activeProfile.id {
                                Label(profile.name, systemImage: "checkmark")
                            } else {
                                Text(profile.name)
                            }
                        }
                    }
                } label: {
                    Label("Switch", systemImage: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(store.settings.accentTheme.color.opacity(0.14), in: Capsule())
                }
            }

            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.85))
                        .frame(width: 60, height: 60)
                    CrosshairRenderer(config: store.activeProfile.crosshair, scale: 0.72)
                        .frame(width: 52, height: 52)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.activeProfile.name)
                        .font(.title3.weight(.bold))
                    Text(store.activeProfile.gameTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Label("\(store.activeProfile.controls.count) controls", systemImage: "hand.tap")
                        Label(store.t(store.activeProfile.crosshair.style.displayNameKey), systemImage: "scope")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var quickActionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickActionTile(
                title: store.t("tab.touch"),
                subtitle: "\(store.activeProfile.controls.count) buttons",
                icon: "hand.tap.fill",
                color: .blue
            ) {
                store.selectedTab = 1
            }

            quickActionTile(
                title: store.t("tab.macros"),
                subtitle: "\(store.macros.count) sequences",
                icon: "bolt.circle.fill",
                color: .purple
            ) {
                store.selectedTab = 2
            }

            quickActionTile(
                title: store.t("tab.crosshair"),
                subtitle: store.activeProfile.crosshair.isEnabled ? "Enabled" : "Disabled",
                icon: "scope",
                color: .green
            ) {
                store.selectedTab = 3
            }

            quickActionTile(
                title: store.t("settings.title"),
                subtitle: store.settings.language.nativeName,
                icon: "gearshape.fill",
                color: .orange
            ) {
                showSettings = true
            }
        }
    }

    private func quickActionTile(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var pipHUDCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(store.t("dashboard.pipHud"), systemImage: "pip.enter")
                    .font(.headline)
                Spacer()
                Text(store.pipHUD.isPiPActive ? "LIVE" : "AVKit")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (store.pipHUD.isPiPActive ? Color.green : Color.secondary).opacity(0.18),
                        in: Capsule()
                    )
                    .foregroundStyle(store.pipHUD.isPiPActive ? .green : .secondary)
            }

            Text("Launch an official iOS Picture-in-Picture reference window showing your active profile, crosshair preview, and macro status while switching apps.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                PiPHUDHostView(displayLayer: store.pipHUD.displayLayer)
                    .frame(width: 96, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                Spacer()

                Button {
                    store.syncPiPHUD()
                    store.pipHUD.togglePiP()
                } label: {
                    Label(
                        store.pipHUD.isPiPActive ? store.t("dashboard.stopPip") : store.t("dashboard.startPip"),
                        systemImage: store.pipHUD.isPiPActive ? "pip.exit" : "pip.enter"
                    )
                    .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.pipHUD.isPiPSupported)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var hardwareStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(store.t("dashboard.hardwareStatus"), systemImage: "gamecontroller.fill")
                .font(.headline)

            HStack {
                Image(systemName: store.controllerService.isConnected ? "gamecontroller.fill" : "gamecontroller")
                    .foregroundStyle(store.controllerService.isConnected ? .green : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.controllerService.connectedControllerName ?? "MFi / Bluetooth Controller")
                        .font(.subheadline.weight(.medium))
                    Text(store.controllerService.lastInputSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Circle()
                    .fill(store.controllerService.isConnected ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 10, height: 10)
            }

            Divider()

            Button {
                showHardwareBridge = true
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundStyle(store.bleBridge.connectionState == .connected ? .blue : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.t("settings.hardware"))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text(store.bleBridge.connectedDeviceName ?? store.bleBridge.connectionState.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var quickMacrosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Quick Macro Runner", systemImage: "bolt.fill")
                    .font(.headline)
                Spacer()
                if store.macroEngine.isRunning {
                    Button(role: .destructive) {
                        store.macroEngine.stop()
                    } label: {
                        Label(store.t("macro.stop"), systemImage: "stop.fill")
                            .font(.caption.weight(.bold))
                    }
                    .buttonStyle(.bordered)
                }
            }

            if store.macros.isEmpty {
                Text("No macros created yet. Open the Macros tab to record or build a sequence.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.macros.prefix(3)) { macro in
                    let isRunningThis = store.macroEngine.isRunning && store.macroEngine.activeMacroId == macro.id
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(macro.name)
                                .font(.subheadline.weight(.semibold))
                            Text("\(macro.steps.count) steps • \(macro.estimatedSinglePassMs) ms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            if isRunningThis {
                                store.macroEngine.stop()
                            } else {
                                store.runMacro(macro)
                            }
                        } label: {
                            Image(systemName: isRunningThis ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(isRunningThis ? .red : store.settings.accentTheme.color)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var iosCapabilitiesBanner: some View {
        Button {
            showCapabilities = true
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.t("dashboard.iosNoticeTitle"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(store.t("dashboard.iosNoticeBody"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
