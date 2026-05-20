import UIKit

enum RuntimeEnvironment {
    static var isNativePhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone &&
        !UIDevice.current.model.localizedCaseInsensitiveContains("iPad")
    }
}
