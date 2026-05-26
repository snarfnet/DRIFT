import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

class DriftAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if RuntimeEnvironment.isNativeDevice {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
        return true
    }
}

@main
struct DriftApp: App {
    @UIApplicationDelegateAdaptor(DriftAppDelegate.self) var appDelegate
    @State private var attRequested = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    guard !attRequested else { return }
                    attRequested = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ATTrackingManager.requestTrackingAuthorization { _ in }
                    }
                }
        }
    }
}
