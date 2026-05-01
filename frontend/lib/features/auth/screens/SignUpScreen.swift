import SwiftUI

public struct SignUpScreen: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    public var onCreateAccount: () -> Void
    public var onRequestLogIn: () -> Void

    public init(
        onCreateAccount: @escaping () -> Void = {},
        onRequestLogIn: @escaping () -> Void = {}
    ) {
        self.onCreateAccount = onCreateAccount
        self.onRequestLogIn = onRequestLogIn
    }

    public var body: some View {
        ZStack {
            AuthTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 32) {
                    Text("Sign up")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(AuthTheme.labelText)
                    AuthFormContainer {
                        AuthLabeledTextField(title: "First name", text: $firstName)
                        AuthLabeledTextField(title: "Last name", text: $lastName)
                        AuthLabeledTextField(title: "Email", text: $email)
                        AuthLabeledTextField(title: "Password", text: $password, isSecure: true)
                        AuthPrimaryButton(title: "Create account", action: onCreateAccount)
                        AuthModeSwitchRow(lead: "Already have an account?", actionTitle: "Log in", action: onRequestLogIn)
                    }
                }
                .padding(.vertical, 48)
                .padding(.horizontal, AuthTheme.horizontalPadding)
            }
        }
    }
}

#if DEBUG
struct SignUpScreen_Previews: PreviewProvider {
    static var previews: some View {
        SignUpScreen()
    }
}
#endif
