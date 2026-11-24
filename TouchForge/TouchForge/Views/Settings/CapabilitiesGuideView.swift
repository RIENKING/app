import SwiftUI

struct CapabilitiesGuideView: View {
    var body: some View {
        List {
            Section("1. Fully Native on Standard iOS (No Jailbreak)") {
                capabilityRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "Touch Layout Studio & Practice Canvas",
                    detail: "Design, move, resize, style, and test custom virtual button layouts with normalized screen coordinates, snap-to-grid, opacity, and real haptic feedback."
                )
                capabilityRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "Macro Recorder, Editor & Replay Engine",
                    detail: "Capture real touch timing and swipe gestures, configure repeat/infinite loops and playback speed, and replay with live visual step tracking."
                )
                capabilityRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "Crosshair Designer & Profile Manager",
                    detail: "7 vector reticle styles with full geometry, color, opacity, and offset controls. Import/export individual profiles or full JSON backups."
                )
                capabilityRow(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    title: "MFi / Bluetooth GameController Integration",
                    detail: "Uses Apple's official GameController framework to detect Xbox, PlayStation DualSense, Backbone, and MFi controllers and bind buttons to macros."
                )
            }

            Section("2. Official Apple System & Accessibility Workflows") {
                capabilityRow(
                    icon: "pip.enter",
                    color: .blue,
                    title: "Floating Picture-in-Picture (PiP) HUD",
                    detail: "Uses Apple's AVKit Picture-in-Picture API to float a live profile, crosshair reference, and macro status window while you switch apps."
                )
                capabilityRow(
                    icon: "command.circle.fill",
                    color: .blue,
                    title: "Apple Shortcuts, Siri, Action Button & Back Tap",
                    detail: "Exposed via Apple's AppIntents framework so you can switch profiles or start/stop macros from iPhone Action Button or Settings → Accessibility → Touch → Back Tap."
                )
                capabilityRow(
                    icon: "accessibility",
                    color: .blue,
                    title: "iOS AssistiveTouch & Switch Control Recipes",
                    detail: "For OS-level custom gestures inside other apps, iOS officially provides Settings → Accessibility → Touch → AssistiveTouch → Create New Gesture, and Switch Control Recipes."
                )
            }

            Section("3. Requires Optional External Hardware") {
                capabilityRow(
                    icon: "antenna.radiowaves.left.and.right",
                    color: .orange,
                    title: "Cross-App Macro & Button Injection (BLE HID Bridge)",
                    detail: "Pair an external Bluetooth HID microcontroller (ESP32-S3, Pico W, nRF52) via TouchForge's CoreBluetooth bridge. iOS officially accepts external Bluetooth HID pointers/keyboards."
                )
            }

            Section("4. Intentionally Restricted by iOS Security") {
                capabilityRow(
                    icon: "lock.shield.fill",
                    color: .red,
                    title: "Direct Background Touch Injection",
                    detail: "Apple's iOS sandbox prohibits ordinary apps from synthesizing touch events directly into third-party games without jailbreak or external HID hardware."
                )
                capabilityRow(
                    icon: "rectangle.on.rectangle.slash",
                    color: .red,
                    title: "Full-Screen Touch-Through Overlays",
                    detail: "Unlike Android's SYSTEM_ALERT_WINDOW, iOS does not allow third-party apps to draw transparent touch-through overlays over other apps. TouchForge uses official PiP for floating reference HUDs instead."
                )
            }
        }
        .navigationTitle("iOS Capabilities")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func capabilityRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 26)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
