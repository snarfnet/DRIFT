import UIKit

enum RuntimeEnvironment {
    static var isNativePhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone &&
        !UIDevice.current.model.localizedCaseInsensitiveContains("iPad")
    }

    /// iPhone/iPad 両方の実機で true（シミュレータ・Mac Catalyst は除外）
    static var isNativeDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #elseif targetEnvironment(macCatalyst)
        return false
        #else
        let idiom = UIDevice.current.userInterfaceIdiom
        return idiom == .phone || idiom == .pad
        #endif
    }
}
