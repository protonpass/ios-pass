//
//  Unlocker.swift
//  ProtonCore-Settings - Created on 27.10.2020.
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
import LocalAuthentication

/// Typealias of LockReader & BioUnlocker & PinUnlocker
public typealias Unlocker = LockReader & BioUnlocker & PinUnlocker

/// A type that informs about the locking state of the protection of the system.
///
/// The system can be protected in a restricted, but not exclusive between them, manner by a biometric lock
/// or a password defined by the user.
public protocol LockReader {

    /// Bool that indicated if biometric protection is enabled.
    var isBioProtected: Bool { get }

    /// Bool that indicated if password protection is enabled.
    var isPinProtected: Bool { get }
}

extension LockReader {
    public func getLockMode() throws -> LockMode {
        let pin = isPinProtected
        let bio = isBioProtected

        switch (pin, bio) {
        case (true, true):
            return .mix
        case (false, true):
            return .bio
        case (true, false):
            return .pin
        default:
            throw NSError(domain: "No protection defined", code: 0, userInfo: nil)
        }
    }
}

/// A type that is able to unlock the system using biometrics.
public protocol BioUnlocker {
    typealias UnlockResult = (Bool) -> Void

    /// Requests Biometric unlock
    /// - Parameters:
    ///   - completion: Closure to be executed on finishing the unlock request
    func bioUnlock(completion: @escaping UnlockResult)
}

/// A type that is able to unlock the system using a password.
public protocol PinUnlocker {
    typealias UnlockResult = (Bool) -> Void

    /// Requests Password unlock
    /// - Parameters:
    ///   - pin: Password used when creating the Password protection
    ///   - completion: Closure to be executed on finishing the unlock request
    func pinUnlock(pin: String, completion: @escaping UnlockResult)
}
