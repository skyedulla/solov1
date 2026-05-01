import Foundation
import SwiftUI

/// Log in vs sign up while the app has no “main” shell yet; extend with session-driven routes later.
public enum AuthRoute: Hashable, Sendable {
    case login
    case signUp
}

/// Coordinates which auth screen is shown; inject from the app entry with ``AuthRootView``.
@MainActor
public final class AuthFlowViewModel: ObservableObject {
    @Published public var route: AuthRoute = .login

    public init() {}

    public func goToSignUp() {
        route = .signUp
    }

    public func goToLogIn() {
        route = .login
    }
}
