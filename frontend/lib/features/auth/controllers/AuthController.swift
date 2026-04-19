import Foundation
import Supabase

/// Coordinates auth flows using Supabase Auth (`signIn`, `signUp`).
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
}
