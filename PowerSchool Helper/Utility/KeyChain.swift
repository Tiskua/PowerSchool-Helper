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

        if SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == noErr {
            print("Password has changed")
        } else {
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
    
    func deletePassword(service: String, account: String) throws {
        let query: [String: AnyObject] = [
            // kSecAttrService,  kSecAttrAccount, and kSecClass
            // uniquely identify the item to delete in Keychain
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecClass as String: kSecClassGenericPassword
        ]

        // SecItemDelete attempts to perform a delete operation
        // for the item identified by query. The status indicates
        // if the operation succeeded or failed.
        let status = SecItemDelete(query as CFDictionary)

        // Any status other than errSecSuccess indicates the
        // delete operation failed.
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func removePassword(username: String) {
        do {
            try deletePassword(
                service: "powerschool-helper.com",
                account: username)
            print("DELETED PASSWORD")
        } catch {
        
        }
    }
    
    func saveLoginDetails(username: String, password: String) {
        do {
            try saveLogin(
                service: "powerschool-helper.com",
                account: username,
                password: password.data(using: .utf8) ?? Data()
            )
        } catch {}
    }
    
    func getPassword(username: String) -> String {
        guard let data = getLogin(
            service: "powerschool-helper.com",
            account: username
        ) else {
            print("FAILED TO READ PASSWORD")
            return ""
        }
        let password = String(decoding: data, as: UTF8.self)
        return password
    }
}
