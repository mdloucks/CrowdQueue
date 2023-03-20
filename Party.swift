//
//  Party.swift
//  Musivote
//
//  Created by Matthew Loucks on 3/9/23.
//

import Foundation
import PostgREST


// Responsible for creating, deleting, and updating parties

class Party {
    
    /**
     Is there an active party associated with this user?
     */
    static func partyExists() async -> Bool {
        struct DefaultsKeys {
            static let partyCode = "partyCode"
        }
        let partyCode = await getPartyCode()
        
        if partyCode == nil || partyCode ?? 0 <= 0 {
            return false
        }
        
        return true
    }
    
    /**
     Create a party and return the party_code
     */
    static func create() async -> Int? {
        
        print("### Creating party")

        let client = getSupabaseConnection()
        
        let deviceToken: String = getDeviceToken()

//            insert
        struct InsertModel: Encodable, Decodable {
            let device_token: String?
            let party_code: Int?
        }
        
        let insertData = InsertModel(device_token: deviceToken, party_code: nil)
        let query = client!.database
            .from("party")
            .insert(values: insertData,
                    returning: .representation)
            .select()
            

        do {

            let response: [InsertModel] = try await query.execute().value
            print("RESPONSE \(response)")
            
            if response.count <= 0 {
                return nil
            }
            
            let partyCode = response[0].party_code
            return partyCode
            
            
        } catch {
            print("### Insert Error: \(error)")
        }
        
        return nil
    }
    
    static func getPartyCode() async -> Int? {
        
        print("### Retrieving party code")
        
        let client = getSupabaseConnection()
        let deviceToken: String = getDeviceToken()
        
        struct InsertModel: Encodable, Decodable {
            let device_token: String
            let party_code: Int?
        }
        
        let insertData: InsertModel = InsertModel(device_token: deviceToken, party_code: nil)
        
        let query = client!.database
                    .from("party")
                    .select()
                    .match(query: ["device_token" : insertData.device_token])
        
        do {
            let response: [InsertModel] = try await query.execute().value
            print("### Returned: \(response)")
            
//            no verdict
            if response.count <= 0 {
                return nil
            }
            
            let partyCode = response[0].party_code
            return partyCode
            
        } catch {
            print("### Insert Error: \(error)")
        }
        
        return nil
    }
    

    /**
     Delete the current party as defined by the currently saved device token
     */
    static func delete() async -> Bool {
        let client = getSupabaseConnection()
        let deviceToken: String = getDeviceToken()
        
        struct InsertModel: Encodable, Decodable {
            let device_token: String
            let party_code: Int?
        }
        
        let insertData: InsertModel = InsertModel(device_token: deviceToken, party_code: nil)
        
        let query = client!.database
                    .from("party")
                    .delete()
                    .match(query: ["device_token" : insertData.device_token])
        
        do {
            let response: [InsertModel] = try await query.execute().value
//          TODO: relook at this later to actually verify it's being deleted
//          Right now if we get a response, we can just assume it was deleted
//          and if not, it probably doesn't exist.
            return true
            
            
        } catch {
            print("### Insert Error: \(error)")
        }
        
        return false
    }

}

