import Foundation

/// Central place for API and Supabase configuration. Mirrors `.env` via the Xcode scheme,
/// xcconfig → Info.plist, or process environment — not hardcoded in source.
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
}
