import SwiftUI

@main
struct TouchForgeApp: App {
    @StateObject private var store = AppStore.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .preferredColorScheme(store.settings.appearance.colorScheme)
                .tint(store.settings.accentTheme.color)
        }
    }
}
