//
//  API+Keychain.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Foundation
import Security

// MARK: - Keychain

extension API {
    func updateKeychain(withCredential credential: APICredential) throws {
        let credentialData = try API.Encoder().encode(credential)
        
        let updateQuery =
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "WishAPI",
        ] as CFDictionary
        
        let updateAttributes =
        [
            kSecAttrService as String: "WishAPI",
            kSecValueData as String: credentialData,
        ] as CFDictionary
        
        let updateStatus = SecItemUpdate(updateQuery, updateAttributes)
        
        guard updateStatus != errSecItemNotFound else {
            let addQuery =
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "WishAPI",
                kSecValueData as String: credentialData,
            ] as CFDictionary
            
            let addStatus = SecItemAdd(addQuery, nil)
            
            guard addStatus == errSecSuccess else {
                throw .api.keychain(.unableToAdd)
            }
            
            return
        }
        
        guard updateStatus == errSecSuccess else {
            throw .api.keychain(.unableToUpdate)
        }
    }
    
    var keychainCredential: APICredential? {
        get {
            let getQuery =
            [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "WishAPI",
                kSecReturnData as String: true,
            ] as CFDictionary
            
            var getItem: CFTypeRef?
            
            let getStatus = SecItemCopyMatching(getQuery, &getItem)
            
            guard getStatus == errSecSuccess,
                  let credentialData = getItem as? Data,
                  let credential = try? API.Decoder().decode(APICredential.self, from: credentialData)
            else {
                return nil
            }
            
            return credential
        }
        
        set(credential) {
            defer {
                session = cleanSession
            }
            
            guard let credential = credential else {
                let deleteQuery =
                [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: "WishAPI",
                ] as CFDictionary
                
                let deleteStatus = SecItemDelete(deleteQuery)
                
                guard deleteStatus == errSecSuccess else { return }
                
                return
            }
            
            try? updateKeychain(withCredential: credential)
        }
    }
}
