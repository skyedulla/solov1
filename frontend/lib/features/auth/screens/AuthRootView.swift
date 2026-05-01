import SwiftUI

/// Shell that switches between auth screens; navigation state lives in ``AuthFlowViewModel``.
public struct AuthRootView: View {
    @EnvironmentObject private var authFlow: AuthFlowViewModel

    public init() {}

    public var body: some View {
        Group {
            switch authFlow.route {
            case .login:
                LoginScreen(
                    onLogIn: {},
                    onRequestSignUp: { authFlow.goToSignUp() }
                )
            case .signUp:
                SignUpScreen(
                    onCreateAccount: {},
                    onRequestLogIn: { authFlow.goToLogIn() }
                )
            }
        }
        .frame(minWidth: 400, minHeight: 520)
    }
}
