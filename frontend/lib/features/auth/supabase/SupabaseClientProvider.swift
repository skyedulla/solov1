import Foundation
import Supabase

/// Shared Supabase client for the app. URL, anon key, and OAuth **`redirectToURL`** come from
/// **`AppConfiguration`** (environment / Info.plist mirroring `.env`), not literals.
public enum SupabaseClientProvider {
    public static let shared: SupabaseClient = {
        SupabaseClient(
            supabaseURL: AppConfiguration.supabaseURL,
            supabaseKey: AppConfiguration.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: AppConfiguration.googleWebOAuthRedirectURL
                )
            )
        )
    }()
}
