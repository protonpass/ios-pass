//
// MainKeyProvider.swift
// Proton Pass - Created on 04/07/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import ProtonCoreKeymaker
import ProtonCoreSettings

// sourcery: AutoMockable
public protocol MainKeyProvider: Sendable, AnyObject {
    var mainKey: MainKey? { get }
}

extension Keymaker: @unchecked @retroactive Sendable, MainKeyProvider {}

extension Keymaker: AutoLocker {
    public var autolockerTimeout: LockTime {
        LockTime(rawValue: PPKeychain().lockTime.rawValue)
    }

    public func setAutolockerTimeout(_ timeout: LockTime) {
        PPKeychain().lockTime = .init(rawValue: timeout.rawValue)
    }
}

/*
 // MARK: - Unlocking
 extension Keymaker: PinUnlocker {
     public func pinUnlock(pin: String, completion: @escaping UnlockResult) {
         obtainMainKey(with: PinProtection(pin: pin, keychain: PPKeychain())) { key in
             guard let key, !key.isEmpty else {
                 print("Tried to unlock with PIN ❌.")
                 return completion(false)
             }
             print("Unlock with PIN ✅. \n Key: \(key)")
             completion(true)
         }
     }
 }

 // MARK: - Pin locking
 extension Keymaker: PinLocker { }

 extension Keymaker: PinLockActivator {
     public func activatePin(pin: String, completion: @escaping (Bool) -> Void) {
         let protector = PinProtection(pin: pin, keychain: PPKeychain())
         activate(protector) { success in
             let result = success ? "succeed ✅" : "failed ❌"
             completion(success)
             print("Activate protection with \(protector.self) \(result)! 🔒")
         }
     }
 }

 extension Keymaker: PinLockDeactivator {
     public func deactivatePin(completion: @escaping (Bool) -> Void) {
         let protector = PinProtection(pin: "12345", keychain: PPKeychain())
         let success = deactivate(protector)
         let result = success ? "succeed ✅" : "failed ❌"
         completion(success)
         print("Deactivate protection with \(protector.self) \(result) 🗝🔓!")
     }
 }

 extension Keymaker: BioLocker { }

 extension Keymaker: BioLockActivator {
     public func activateBio(completion: @escaping (Bool) -> Void) {
         let protector = BioProtection(keychain: PPKeychain())
         activate(protector) { success in
             let result = success ? "succeed ✅" : "failed ❌"
             completion(success)
             print("Activate protection with \(protector.self) \(result)! 🔒")
         }
     }
 }

 extension Keymaker: BioLockDeactivator {
     public func deactivateBio(completion: @escaping (Bool) -> Void) {
         let protector = BioProtection(keychain: PPKeychain())
         let success = deactivate(protector)
         let result = success ? "succeed ✅" : "failed ❌"
         completion(success)
         print("Deactivate protection with \(protector.self) \(result) 🗝🔓!")
     }
 }

 extension Keymaker: BioUnlocker {
     public func bioUnlock(completion: @escaping UnlockResult) {
         obtainMainKey(with: BioProtection(keychain: PPKeychain())) { key in
             guard let key, !key.isEmpty else {
                 print("Tried to unlock with BIO ❌.")
                 return completion(false)
             }
             print("Unlock with BIO ✅. \n Key: \(key)")
             completion(true)
         }
     }
 }

 extension Keymaker: LockReader {
     public var isBioProtected: Bool {
         isProtectorActive(BioProtection.self)
     }

     public var isPinProtected: Bool {
         isProtectorActive(PinProtection.self)
     }
 }
 */
