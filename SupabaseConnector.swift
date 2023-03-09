//
//  SupabaseConnector.swift
//  Musivote
//
//  Created by Matthew Loucks on 2/26/23.
//

import Foundation
import Supabase


/**
 Will return a supabase connection using the ANON key
 */
func getSupabaseConnection() -> SupabaseClient? {
    let optionalUrl = URL(string: "https://kofhhbgmezymusfukmpz.supabase.co")
    
    guard let supabaseUrl = optionalUrl else {
        return nil
    }
    
    let anonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtvZmhoYmdtZXp5bXVzZnVrbXB6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzYzMTM1ODMsImV4cCI6MTk5MTg4OTU4M30.nsmt-MXftcNSw-VZhDuSabirx01RU0dKfZirDLgpIJA"
    
    let client = SupabaseClient(supabaseURL: supabaseUrl, supabaseKey: anonKey)
    
    return client
}
