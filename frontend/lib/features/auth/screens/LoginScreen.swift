import SwiftUI

public struct LoginScreen: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isGoogleSignInBusy = false
    @State private var googleSignInError: String?

    private let authController = AuthController()

    public var onLogIn: () -> Void
    public var onRequestSignUp: () -> Void

    public init(
        onLogIn: @escaping () -> Void = {},
        onRequestSignUp: @escaping () -> Void = {}
    ) {
        self.onLogIn = onLogIn
        self.onRequestSignUp = onRequestSignUp
    }

    public var body: some View {
        ZStack {
            AuthTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 32) {
                    Text("Log in")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(AuthTheme.labelText)
                    AuthFormContainer {
                        googleOAuthButton
                        AuthLabeledTextField(title: "Email", text: $email)
                        AuthLabeledTextField(title: "Password", text: $password, isSecure: true)
                        AuthPrimaryButton(title: "Log in", action: onLogIn)
                        AuthModeSwitchRow(lead: "No account yet?", actionTitle: "Sign up", action: onRequestSignUp)
                    }
                }
                .padding(.vertical, 48)
                .padding(.horizontal, AuthTheme.horizontalPadding)
            }
        }
        .alert("Google sign-in", isPresented: Binding(
            get: { googleSignInError != nil },
            set: { if !$0 { googleSignInError = nil } }
        )) {
            Button("OK", role: .cancel) { googleSignInError = nil }
        } message: {
            if let googleSignInError {
                Text(googleSignInError)
            }
        }
    }

    private var googleOAuthButton: some View {
        let side = AuthTheme.googleOAuthButtonSide
        return Button {
            Task { await runGoogleSignIn() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: AuthTheme.googleOAuthButtonCorner, style: .continuous)
                    .fill(Color.white)
                    .frame(width: side, height: side)
                    .overlay {
                        RoundedRectangle(cornerRadius: AuthTheme.googleOAuthButtonCorner, style: .continuous)
                            .strokeBorder(AuthTheme.fieldBorder, lineWidth: 1)
                    }
                AuthGoogleMark(side: side * 0.48)
            }
            .frame(width: side, height: side)
            .contentShape(RoundedRectangle(cornerRadius: AuthTheme.googleOAuthButtonCorner, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isGoogleSignInBusy)
        .opacity(isGoogleSignInBusy ? 0.55 : 1)
        .accessibilityLabel("Sign in with Google")
        .frame(maxWidth: .infinity)
    }

    private func runGoogleSignIn() async {
        await MainActor.run { isGoogleSignInBusy = true }
        do {
            _ = try await authController.googleSignIn()
            await MainActor.run {
                isGoogleSignInBusy = false
                onLogIn()
            }
        } catch {
            await MainActor.run {
                isGoogleSignInBusy = false
                googleSignInError = error.localizedDescription
            }
        }
    }
}

#if DEBUG
struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen()
    }
}
#endif
