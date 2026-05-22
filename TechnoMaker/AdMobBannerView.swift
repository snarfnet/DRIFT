import SwiftUI
import GoogleMobileAds
import UIKit

private let driftAdMobBannerUnitID = "ca-app-pub-9404799280370656/8085919905"

struct AdMobBannerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .clear

        guard RuntimeEnvironment.isNativeDevice else {
            return controller
        }

        guard let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              !appID.isEmpty else {
            return controller
        }

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = driftAdMobBannerUnitID
        bannerView.rootViewController = controller
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        controller.view.addSubview(bannerView)
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor)
        ])

        bannerView.load(Request())
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
