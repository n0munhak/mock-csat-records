//
//  KeychainHelper.swift
//  Mock CSAT Records
//
//  Created by Seongwon Min on 8/8/26.
//

import Foundation
import Security
import CryptoKit

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case unexpectedData
    case unhandledError(status: OSStatus)
}

final class KeychainHelper {
    private let defaults = UserDefaults.standard
    
    var prefSyncKey: String {
        get {
            return defaults.object(forKey: "syncing_key") as? String ?? ""
        }
        set {
            defaults.set(newValue, forKey: "syncing_key")
        }
    }
    
    static let shared = KeychainHelper()
    private init() {}
    
    private let service = "\(Bundle.main.bundleIdentifier!).sync"
    
    func save(key: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: kCFBooleanTrue!,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
                kSecAttrSynchronizable as String: kCFBooleanTrue!,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
            ]
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: data
            ]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func read(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kCFBooleanTrue!
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound { throw KeychainError.itemNotFound }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = dataTypeRef as? Data else {
            throw KeychainError.unexpectedData
        }
        
        return data
    }
    
    func getSymmetricKey() throws -> SymmetricKey {
        let keyName = "user_encryption_symmetric_key_base64"
        let oldKeyName = "user_encryption_symmetric_key"
        do {
            let data = try read(key: keyName)
            prefSyncKey = String(data: data, encoding: .utf8)!
            return SymmetricKey(data: Data(base64Encoded: String(data: data, encoding: .utf8)!)!)
        } catch KeychainError.itemNotFound {
            do {
                let rawData = try read(key: oldKeyName)
                let b64Encoded = rawData.base64EncodedString()
                prefSyncKey = b64Encoded
                try save(key: keyName, data: b64Encoded.data(using: .utf8)!)
                return SymmetricKey(data: rawData)
            } catch KeychainError.itemNotFound {
                let newKey = SymmetricKey(size: .bits256)
                let keyData = newKey.withUnsafeBytes { Data($0) }
                try save(key: keyName, data: keyData.base64EncodedString().data(using: .utf8)!)
                return newKey
            }
        }
    }
    
    func setSymmetricKey(b64EncodedKey: String) throws {
        let keyName = "user_encryption_symmetric_key_base64"
        prefSyncKey = b64EncodedKey
        try save(key: keyName, data: b64EncodedKey.data(using: .utf8)!)
    }
    
    func saveFirestoreAuth(email: String, password: String) throws {
        let authData = try JSONEncoder().encode(["email": email, "password": password])
        try save(key: "firestore_auth_credentials", data: authData)
    }
    
    func getFirestoreAuth() throws -> (email: String, password: String) {
        let data = try read(key: "firestore_auth_credentials")
        let dict = try JSONDecoder().decode([String: String].self, from: data)
        guard let email = dict["email"], let password = dict["password"] else {
            throw KeychainError.unexpectedData
        }
        return (email, password)
    }
}
