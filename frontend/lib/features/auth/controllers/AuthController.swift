import Foundation
import Supabase

enum AuthValidationError: Error, LocalizedError {
    case firstNameRequired
    case lastNameRequired

    var errorDescription: String? {
        switch self {
        case .firstNameRequired:
            return "First name is required."
        case .lastNameRequired:
            return "Last name is required."
        }
    }
}

/// Coordinates auth flows using Supabase Auth (`signIn`, `signUp`, `resetPassword`, `logout`).
public final class AuthController: Sendable {
    private let supabase: SupabaseClient

    public init(supabase: SupabaseClient = SupabaseClientProvider.shared) {
        self.supabase = supabase
    }

    public func login(model: AuthModel) async throws -> Session {
        try await supabase.auth.signIn(
            email: model.email,
            password: model.password
        )
    }

    public func signUp(model: AuthModel) async throws -> AuthResponse {
        let firstName = model.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = model.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !firstName.isEmpty else { throw AuthValidationError.firstNameRequired }
        guard !lastName.isEmpty else { throw AuthValidationError.lastNameRequired }

        return try await supabase.auth.signUp(
            email: model.email,
            password: model.password,
            data: [
                "first_name": .string(firstName),
                "last_name": .string(lastName),
            ]
        )
    }

    /// Sends a password-recovery email. Configure **Redirect URLs** in the Supabase dashboard; use `redirectTo` for the same URL when deep-linking back into the app.
    public func resetPassword(email: String, redirectTo: URL? = nil) async throws {
        try await supabase.auth.resetPasswordForEmail(email, redirectTo: redirectTo)
    }

    /// Ends the session locally and revokes refresh tokens on the server (Supabase Auth `logout`).
    public func logout() async throws {
        try await supabase.auth.signOut()
    }
}
