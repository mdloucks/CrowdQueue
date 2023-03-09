//
//  DeviceToken.swift
//  Musivote
//
//  Created by Matthew Loucks on 2/27/23.
//

import Foundation


/**
 get the device token
 */
func getDeviceToken() -> String {
    struct DefaultsKeys {
        static let deviceToken = "deviceToken"
    }
    
    let defaults = UserDefaults.standard
    guard let deviceToken = defaults.string(forKey: DefaultsKeys.deviceToken) else { return "" }
    
    return deviceToken
}

/**
 Save the device token to local storage so then it can be accessed by signup/login services
 */
func setDeviceToken(_ token: String) {
    struct DefaultsKeys {
        static let deviceToken = "deviceToken"
    }
    
    let defaults = UserDefaults.standard
    
    defaults.set(token, forKey: DefaultsKeys.deviceToken)
}
