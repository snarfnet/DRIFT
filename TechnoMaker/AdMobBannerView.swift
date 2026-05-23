import SwiftUI
import GoogleMobileAds
import UIKit

private let driftAdMobBannerUnitID = "ca-app-pub-9404799280370656/8085919905"

struct AdMobBannerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = BannerHostController()
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class BannerHostController: UIViewController {
    private var bannerView: BannerView?
    private var didLoadAd = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didLoadAd else { return }
        didLoadAd = true
        loadBanner()
    }

    private func loadBanner() {
        guard RuntimeEnvironment.isNativeDevice else { return }

        guard let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String,
              !appID.isEmpty else { return }

        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = driftAdMobBannerUnitID
        banner.rootViewController = self
        banner.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        banner.load(Request())
        self.bannerView = banner
    }
}
