import Foundation

/// Central place for API, Supabase, and OAuth redirect configuration. Mirrors `.env` via the Xcode
/// scheme, xcconfig → Info.plist, or process environment — not hardcoded in source.
public enum AppConfiguration {
    public static var apiBaseURL: URL {
        let raw =
            ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String

        guard let raw, !raw.isEmpty, let url = URL(string: raw) else {
            preconditionFailure(
                "API_BASE_URL is not set. Add it to your .env for documentation parity, "
                    + "then inject the same value via the scheme environment or Info.plist (see project rules).")
        }
        return url
    }

    /// Supabase project URL (same as `SUPABASE_URL` in `.env`).
    public static var supabaseURL: URL {
        let raw =
            ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String

        guard let raw, !raw.isEmpty, let url = URL(string: raw) else {
            preconditionFailure(
                "SUPABASE_URL is not set. Mirror `.env` into the scheme environment or Info.plist (see project rules).")
        }
        return url
    }

    /// Supabase anonymous key (same as `SUPABASE_ANON_KEY` in `.env`).
    public static var supabaseAnonKey: String {
        let raw =
            ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        guard let raw, !raw.isEmpty else {
            preconditionFailure(
                "SUPABASE_ANON_KEY is not set. Mirror `.env` into the scheme environment or Info.plist (see project rules).")
        }
        return raw
    }

    /// Google **web** OAuth client ID (`GOOGLE_WEB_OAUTH_CLIENT_ID` in `.env`).
    ///
    /// Supabase’s browser-based OAuth does not require this value in-app; it is exposed for parity
    /// with `.env` and for future flows (e.g. native Google Sign-In + ID token). **Do not** read
    /// `GOOGLE_WEB_OAUTH_CLIENT_SECRET` in the client.
    public static var googleWebOAuthClientID: String? {
        let raw =
            ProcessInfo.processInfo.environment["GOOGLE_WEB_OAUTH_CLIENT_ID"]
            ?? Bundle.main.object(forInfoDictionaryKey: "GOOGLE_WEB_OAUTH_CLIENT_ID") as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    /// Redirect URL for Supabase OAuth (PKCE), e.g. `app.solo.macos://oauth-callback`.
    ///
    /// Set **`GOOGLE_WEB_OAUTH_REDIRECT_URL`** in `.env` / Info.plist to match **Authentication → URL
    /// Configuration → Redirect URLs** in Supabase. If unset, uses **`{CFBundleIdentifier}://oauth-callback`**.
    public static var googleWebOAuthRedirectURL: URL {
        let raw =
            ProcessInfo.processInfo.environment["GOOGLE_WEB_OAUTH_REDIRECT_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "GOOGLE_WEB_OAUTH_REDIRECT_URL") as? String

        if let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines))
        {
            return url
        }

        let bundleId = Bundle.main.bundleIdentifier ?? "app.solo.macos"
        guard let url = URL(string: "\(bundleId)://oauth-callback") else {
            preconditionFailure("Could not build default OAuth redirect URL for bundle \(bundleId).")
        }
        return url
    }
}
