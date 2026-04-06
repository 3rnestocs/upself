//
//  AppConfig.swift
//  UpSelf
//
//  Credentials are loaded from Info.plist, which is populated at build time
//  from Secrets.xcconfig (gitignored). See Secrets.template.xcconfig for setup.
//

import Foundation

enum AppConfig {
    /// Supabase project URL. `nil` when Secrets.xcconfig is not configured
    /// (e.g. a fresh clone before the developer fills in Secrets.xcconfig).
    static let supabaseURL: URL? = {
        guard let raw = Bundle.main.infoDictionary?["SupabaseURL"] as? String,
              !raw.isEmpty,
              !raw.hasPrefix("$("),
              let url = URL(string: raw) else { return nil }
        return url
    }()

    /// Supabase anon (publishable) key. Empty string when not configured.
    static let supabaseAnonKey: String = {
        let raw = Bundle.main.infoDictionary?["SupabaseAnonKey"] as? String ?? ""
        return raw.hasPrefix("$(") ? "" : raw
    }()
}
