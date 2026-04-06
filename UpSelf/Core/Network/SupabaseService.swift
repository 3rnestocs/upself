//
//  SupabaseService.swift
//  UpSelf
//
//  Created by Ernesto Contreras on 2/4/26.
//


import Foundation
import Supabase

// El contrato: esto es lo que el resto de la app verá
protocol SupabaseServiceProtocol {
    var client: SupabaseClient { get }
}

// La implementación real
final class SupabaseService: SupabaseServiceProtocol {
    let client: SupabaseClient

    init(url: URL, anonKey: String) {
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }
}

/// Fallback used when Secrets.xcconfig is not configured (missing URL).
/// Prevents a crash while making the misconfiguration obvious via assertionFailure.
final class NoOpSupabaseService: SupabaseServiceProtocol {
    var client: SupabaseClient {
        fatalError("NoOpSupabaseService: Supabase is not configured. See Secrets.template.xcconfig.")
    }
}
