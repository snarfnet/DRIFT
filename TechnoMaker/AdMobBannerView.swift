import SwiftUI
import GoogleMobileAds
import UIKit

private let driftAdMobBannerUnitID = "ca-app-pub-9404799280370656/8085919905"

struct AdMobBannerView: View {
    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)
            BannerViewContainer(
                adUnitID: driftAdMobBannerUnitID,
                adSize: adSize
            )
            .frame(width: adSize.size.width, height: adSize.size.height)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 64)
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.topViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.adSize = adSize
        uiView.rootViewController = UIApplication.shared.topViewController
    }
}

private extension UIApplication {
    var topViewController: UIViewController? {
        let scene = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        return scene?.keyWindow?.rootViewController
    }
}
