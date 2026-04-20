import Foundation
import Supabase

/// Coordinates auth flows using Supabase Auth (`signIn`, `signUp`, `resetPassword`, `logout`).
final class AuthController: Sendable {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseClientProvider.shared) {
        self.supabase = supabase
    }

    func login(model: AuthModel) async throws -> Session {
        try await supabase.auth.signIn(
            email: model.email,
            password: model.password
        )
    }

    func signUp(model: AuthModel) async throws -> AuthResponse {
        try await supabase.auth.signUp(
            email: model.email,
            password: model.password,
            data: [
                "first_name": .string(model.firstName),
                "last_name": .string(model.lastName),
            ]
        )
    }

    /// Sends a password-recovery email. Configure **Redirect URLs** in the Supabase dashboard; use `redirectTo` for the same URL when deep-linking back into the app.
    func resetPassword(email: String, redirectTo: URL? = nil) async throws {
        try await supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo)
    }

    /// Ends the session locally and revokes refresh tokens on the server (Supabase Auth `logout`).
    func logout() async throws {
        try await supabase.auth.signOut()
    }
}
