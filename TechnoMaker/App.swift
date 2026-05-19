import SwiftUI
import GoogleMobileAds

class DriftAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        if UIDevice.current.userInterfaceIdiom == .phone {
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
