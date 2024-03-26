import Foundation
import SwiftKeychainWrapper


final class OAuth2TokenStorage {
    
    var token: String?
    private static let tokenKey:String = "BearerToken"
    
    static var token: String? {
        get {
            return KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if let newValue = newValue {
                KeychainWrapper.standard.set(newValue, forKey: tokenKey)
            } else {
                KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
    
    static func logout() {
        KeychainWrapper.standard.removeObject(forKey: tokenKey)
    }
    
   
}
