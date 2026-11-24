import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $store.selectedTab) {
                DashboardView()
                    .tabItem {
                        Label(store.t("tab.dashboard"), systemImage: "slider.horizontal.3")
                    }
                    .tag(0)

                TouchStudioView()
                    .tabItem {
                        Label(store.t("tab.touch"), systemImage: "hand.tap.fill")
                    }
                    .tag(1)

                MacroListView()
                    .tabItem {
                        Label(store.t("tab.macros"), systemImage: "bolt.circle.fill")
                    }
                    .tag(2)

                CrosshairStudioView()
                    .tabItem {
                        Label(store.t("tab.crosshair"), systemImage: "scope")
                    }
                    .tag(3)

                ProfilesView()
                    .tabItem {
                        Label(store.t("tab.profiles"), systemImage: "rectangle.stack.fill")
                    }
                    .tag(4)
            }

            if let toast = store.toastMessage {
                Text(toast)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.82), in: Capsule())
                    .shadow(radius: 8)
                    .padding(.bottom, 64)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.32, dampingFraction: 0.8), value: store.toastMessage)
            }
        }
    }
}
