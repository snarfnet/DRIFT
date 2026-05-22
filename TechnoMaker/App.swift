import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

class DriftAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if RuntimeEnvironment.isNativeDevice {
            DispatchQueue.main.async {
                MobileAds.shared.start()
            }
        }
        return true
    }
}

@main
struct DriftApp: App {
    @UIApplicationDelegateAdaptor(DriftAppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
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
