//
//  KeyChain.swift
//  PowerSchool Helper
//
//  Created by Branson Campbell on 3/22/23.
//

import UIKit
import Security

class KeychainManager {
    enum KeychainError: Error {
        case duplicateEntry
        case changeFailure
        case unknown(OSStatus)
    }
    
    func saveLogin(service: String, account: String, password: Data) throws {
        let query: [String : AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecValueData as String: password as AnyObject,
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
    
        guard status != errSecDuplicateItem else {
            throw KeychainError.duplicateEntry
        }
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func updatePassword(username: String, newPassword: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: username,
        ]

        let attributes: [String: Any] = [kSecValueData as String: newPassword]

        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) != noErr {
            print("Something went wrong trying to update the password")
        }
    }
    
    func getLogin(service: String, account: String) -> Data? {
        let query: [String : AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecReturnData as String: kCFBooleanTrue,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        return result as? Data
    }
    
    func saveLoginDetails(username: String, password: String) {
        do {
            try saveLogin(
                service: "powerschool-plus.com",
                account: username,
                password: password.data(using: .utf8) ?? Data()
            )
        } catch {}
    }
    
    func getPassword() -> String {
        guard let data = getLogin(
            service: "powerschool-plus.com",
            account: UserDefaults.standard.string(forKey: "login-username") ?? ""
        ) else {
            print("FAILED TO READ PASSWORD")
            return ""
        }
        let password = String(decoding: data, as: UTF8.self)
        return password
    }
    
    func updatePassword(username: String, password: String) {
        if KeychainManager().getPassword() != password {
            do {
                try KeychainManager().saveLogin(service: "powerschool-plus.com", account: username, password: Data(password.utf8))
            } catch {
                 KeychainManager().updatePassword(username: username, newPassword: password)
            }
        }
    }
}
