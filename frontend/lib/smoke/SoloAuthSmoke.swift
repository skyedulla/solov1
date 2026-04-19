import Foundation

/// CLI smoke test: calls `AuthController.signUp` (→ Supabase Auth).
///
/// Run with Supabase env vars (mirror `.env`):
///
///   cd frontend && SUPABASE_URL=... SUPABASE_ANON_KEY=... swift run solo-auth-smoke
///
@main
enum SoloAuthSmoke {
    static func main() async throws {
        let controller = AuthController()
        let model = AuthModel(
            firstName: "Smoke",
            lastName: "Test",
            email: "smoke-\(UUID().uuidString.prefix(8))@example.com",
            password: "password12"
        )

        print("SUPABASE_URL → \(AppConfiguration.supabaseURL.absoluteString)")
        print("Supabase signUp …")

        let response = try await controller.signUp(model: model)

        switch response {
        case .session(let session):
            print("Signed up with session; user id: \(session.user.id)")
        case .user(let user):
            print("Signed up (confirm email if required); user id: \(user.id)")
        }
    }
}
