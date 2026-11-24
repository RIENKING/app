# TouchForge — Panda Touch Pro Alternative for iOS (Swift & SwiftUI)

**TouchForge** is a native iOS 17+ application built with **Swift** and **SwiftUI**, inspired by Panda Touch Pro and engineered strictly with Apple's official APIs—no jailbreak, no private APIs, and no fake login or account requirements.

---

## Implemented Features

### 1. Touch Mapping Studio
- **Create & customize virtual touch controls:** Tap Button, Hold Button, Swipe Pad, Virtual D-Pad, Aim/Look Pad, and Macro Trigger.
- **Direct manipulation:** Drag buttons anywhere on the normalized canvas (with optional Snap-to-Grid and live coordinate readouts), pinch directly on a button to resize, or fine-tune width, height, border width, shape (`Circle`, `Rounded`, `Capsule`, `Ring`), SF Symbol icon, color, opacity/transparency, and haptic intensity in the inspector.
- **Edit Mode & Live Test Canvas:** Switch instantly between layout editing and an interactive test canvas with real `UIImpactFeedbackGenerator` haptics, touch ripple animations, press counters, live macro cursor playback, and live physical controller button highlighting.
- **Per-game layouts:** Every Game Profile stores its own complete control layout and crosshair.

### 2. Macro System
- **Live Gesture Recorder (`MacroRecorderSheet`):** Tap, long-press, or swipe on the capture pad to record real normalized coordinates, gesture types, hold durations, and exact inter-action delays.
- **Full Sequence Editor (`MacroEditorView`):** Add, edit, reorder, or delete steps (`Tap`, `Long Press`, `Swipe`, `Wait Delay`, `Haptic Cue`, `BLE HID Command`), configure repeat counts (1–100×), infinite loop mode, loop delay, playback speed (0.25×–2.5×), and hardware controller triggers.
- **Async Replay Engine (`MacroEngine`):** Swift Concurrency execution engine with Play, Pause/Resume, Stop, live step highlighting, execution log, and optional BLE HID packet forwarding.

### 3. Crosshair Studio
- **7 vector reticle styles** rendered with SwiftUI `Canvas`: Classic Cross, Precision Dot, Circle + Dot, T-Reticle, Chevron, Dynamic Brackets, and Sniper Scope.
- **Full customization:** Size, line thickness, center gap, center dot toggle & size, high-contrast outline, color picker + neon presets, opacity, and X/Y position offsets with 1-tap Reset Center.
- **Preview backdrops:** Dark Grid, Daylight, Forest, and Desert.

### 4. Profile Management
- **CRUD & organization:** Create, edit, duplicate, delete, search, and filter game profiles by genre (`FPS`, `Battle Royale`, `MOBA`, `Action RPG`, `Racing`, `Custom`).
- **Preloaded starter profiles:** Ships with *FPS Tactical Pro*, *MOBA Quick-Cast*, and *Action RPG Dodge* plus 3 starter macros.
- **Real Import & Export:** Export and import individual profiles as `.json` / `.tfprofile` via Apple's native Files picker (`FileDocument`).

### 5. Control Panel, Official iOS Integrations & Settings
- **Modern iOS UI:** Adaptive Light / Dark / System mode, 5 accent color themes, smooth spring animations, and 5 built-in languages (**English**, **Tiếng Việt**, **Español**, **日本語**, **简体中文**).
- **MFi / Bluetooth GameController (`GameController`):** Real-time detection and input binding for Xbox, PlayStation DualSense, Backbone, and MFi controllers.
- **Floating Picture-in-Picture HUD (`AVKit`):** Renders your active profile, crosshair preview, and macro status to an official iOS PiP window that floats while switching apps.
- **Apple Shortcuts, Siri, Action Button & Back Tap (`AppIntents`):** Switch profiles, run macros, or stop macros via Apple Shortcuts.
- **Full Backup & Restore:** Export and restore all profiles, macros, crosshairs, and settings in a single JSON backup file.
- **External BLE HID Bridge (`CoreBluetooth`):** Optional Bluetooth LE client with an open GATT protocol for external HID hardware bridges (ESP32-S3 / Raspberry Pi Pico W / nRF52840).

---

## Official iOS Capabilities vs. Platform Limitations

TouchForge is transparent about what standard iOS permits without jailbreak:

| Capability | Status on Standard iOS | How TouchForge Handles It |
|---|---|---|
| Touch Layout Designer, Test Canvas, Macro Recorder/Editor/Replay, Crosshair Designer, Profiles, Backup/Restore | **100% Native** | Works fully offline on-device with SwiftUI & local JSON storage. |
| Physical Game Controller Input (Xbox / DualSense / Backbone / MFi) | **Official Apple API** | Uses `GameController` framework to monitor buttons/sticks and trigger macros. |
| Floating Reference HUD over Other Apps | **Official Apple API** | Uses `AVPictureInPictureController` (`AVKit`) to float a live HUD window. |
| Action Button / Back Tap / Siri Triggers | **Official Apple API** | Uses `AppIntents` (`SwitchProfileIntent`, `RunMacroIntent`, `StopMacroIntent`). |
| OS-Level Custom Gestures in Other Apps | **Apple Accessibility** | Guided setup for iOS *AssistiveTouch Custom Gestures* & *Switch Control Recipes*. |
| Sending Mapped Inputs/Macros into Third-Party Games | **Requires External Hardware** | Optional `CoreBluetooth` HID Bridge protocol for ESP32-S3 / Pico W acting as an official Bluetooth HID pointer/keyboard. |
| Direct Background Touch Injection or Full-Screen Touch-Through Overlays | **Not Permitted by iOS** | Blocked by Apple's iOS security sandbox; TouchForge does not fake or bypass this. |

---

## Installation Instructions (Build & Install on iPhone)

> **Requirements:** A Mac running **macOS 14+** with **Xcode 15.4 or newer**, an iPhone running **iOS 17.0+**, and a free Apple ID (or paid Apple Developer account).

### Option A: Open the Included Xcode Project Directly (Recommended)
1. Copy the `TouchForge` folder to your Mac.
2. Double-click `TouchForge/TouchForge.xcodeproj` to open it in **Xcode**.
3. In Xcode's left sidebar, click the top-level **TouchForge** project, select the **TouchForge** target, and open the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**, choose your **Team** (your free Apple ID works), and change the **Bundle Identifier** if needed (e.g., `com.yourname.touchforge`).
5. Connect your iPhone via USB (or wireless debugging), select your iPhone as the run destination at the top of Xcode, and press **Run (`⌘R`)**.
6. On your iPhone, if using a free Apple ID, go to **Settings → General → VPN & Device Management**, tap your Apple ID developer certificate, and tap **Trust**.
7. Launch **TouchForge** from your iPhone Home Screen!

### Option B: Regenerate Project via XcodeGen (Optional)
If you prefer regenerating the `.xcodeproj` from `project.yml`:
```bash
brew install xcodegen
cd TouchForge
xcodegen generate
open TouchForge.xcodeproj
```

### Running Unit Tests
In Xcode, press **`⌘U`** to run `TouchForgeTests`, which validates starter state generation, JSON backup/restore round-trips, profile duplication, macro speed scaling, localization fallbacks, and async `MacroEngine` execution.

### Setting Up Apple Shortcuts / Action Button / Back Tap
1. After installing TouchForge, open the built-in **Shortcuts** app on your iPhone.
2. Create a new Shortcut and search for **TouchForge** actions (*Switch TouchForge Profile*, *Run TouchForge Macro*, *Stop Active TouchForge Macro*).
3. Assign the shortcut to **Settings → Action Button** (iPhone 15 Pro and newer) or **Settings → Accessibility → Touch → Back Tap**.
