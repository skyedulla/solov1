import SoloLib
import SwiftUI

/// macOS app entry: open `Solo.xcodeproj` in Xcode, select the **Solo** scheme, Run (⌘R).
@main
struct Solo: App {
    @StateObject private var authFlow = AuthFlowViewModel()

    var body: some Scene {
        WindowGroup {
            AuthRootView()
                .environmentObject(authFlow)
        }
    }
}
