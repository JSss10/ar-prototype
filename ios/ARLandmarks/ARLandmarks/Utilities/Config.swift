//
//  Config.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import Foundation

enum Config {
    static var supabaseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            fatalError("SUPABASE_URL not found in Info.plist")
        }
        return url
    }
    
    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist")
        }
        return key
    }
}
