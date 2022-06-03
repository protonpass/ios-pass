//
//  Crypto+Data.swift
//  ProtonCore-Crypto - Created on 9/11/19.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
#if canImport(ProtonCore_Crypto_VPN)
import ProtonCore_Crypto_VPN
#elseif canImport(ProtonCore_Crypto)
import ProtonCore_Crypto
#endif
import ProtonCore_DataModel

extension Data {
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func decryptAttachment(keyPackage: Data, userKeys: [Data], passphrase: String, keys: [Key]) throws -> Data? {
        do {
            return try decryptAttachmentNonOptional(keyPackage: keyPackage, userKeys: userKeys, passphrase: passphrase, keys: keys)
        } catch CryptoError.attachmentCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }
    
    public func decryptAttachmentNonOptional(keyPackage: Data, userKeys: [Data], passphrase: String, keys: [Key]) throws -> Data {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try key.passphrase(userBinKeys: userKeys, mailboxPassphrase: passphrase)
                return try Crypto().decryptAttachmentNonOptional(keyPacket: keyPackage,
                                                                 dataPacket: self,
                                                                 privateKey: key.privateKey,
                                                                 passphrase: addressKeyPassphrase)
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
            }
        }
        if let error = firstError {
            throw error
        }
        throw CryptoError.attachmentCouldNotBeDecrypted
    }
    
    @available(*, deprecated, message: "Please use the non-optional variant")
    public func getSessionFromPubKeyPackage(userKeys: [Data], passphrase: String, keys: [Key]) throws -> SymmetricKey? {
        do {
            return try getSessionFromPubKeyPackageNonOptional(userKeys: userKeys, passphrase: passphrase, keys: keys)
        } catch CryptoError.sessionKeyCouldNotBeDecrypted {
            return nil
        } catch {
            throw error
        }
    }
    
    public func getSessionFromPubKeyPackageNonOptional(userKeys: [Data], passphrase: String, keys: [Key]) throws -> SymmetricKey {
        var firstError: Error?
        for key in keys {
            do {
                let addressKeyPassphrase = try key.passphrase(userBinKeys: userKeys, mailboxPassphrase: passphrase)
                return try Crypto().getSessionNonOptional(keyPacket: self, privateKey: key.privateKey, passphrase: addressKeyPassphrase)
            } catch let error {
                if firstError == nil {
                    firstError = error
                }
            }
        }
        if let error = firstError {
            throw error
        }
        throw CryptoError.sessionKeyCouldNotBeDecrypted
    }
}
