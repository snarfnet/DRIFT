import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct DriftApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false
    @State private var adMobStarted = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if RuntimeEnvironment.isNativeDevice && !adMobStarted {
                        adMobStarted = true
                        MobileAds.shared.start()
                    }
                }
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active && !attRequested {
                        requestATT()
                    }
                }
        }
    }

    private func requestATT() {
        guard RuntimeEnvironment.isNativeDevice else { return }
        attRequested = true
        // iPadOS 26.5 では UIWindowScene が foregroundActive になるまで待つ必要がある
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  scene.windows.first(where: { $0.isKeyWindow }) != nil else {
                // シーンが準備できていなければリトライ
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    ATTrackingManager.requestTrackingAuthorization { _ in }
                }
                return
            }
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
