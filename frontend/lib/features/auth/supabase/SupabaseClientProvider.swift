import Foundation
import Supabase

/// Shared Supabase client for the app. URL and anon key come from the environment or Info.plist (mirrors `.env`), not literals.
enum SupabaseClientProvider {
    static let shared: SupabaseClient = {
        SupabaseClient(
            supabaseURL: AppConfiguration.supabaseURL,
            supabaseKey: AppConfiguration.supabaseAnonKey,
            options: SupabaseClientOptions()
        )
    }()
}
