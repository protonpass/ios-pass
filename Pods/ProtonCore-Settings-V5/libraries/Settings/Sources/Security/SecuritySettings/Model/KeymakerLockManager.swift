//
//  KeymakerLockManager.swift
//  ProtonCore-Settings - Created on 11.11.2020.
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

public class KeymakerLockManager: Locker {
    public let lockReader: LockReader
    private let pinLocker: PinLocker
    private let bioLocker: BioLocker
    private let autoLocker: AutoLocker

    public init(lockReader: LockReader, pinLocker: PinLocker, bioLocker: BioLocker, autoLocker: AutoLocker) {
        self.lockReader = lockReader
        self.pinLocker = pinLocker
        self.bioLocker = bioLocker
        self.autoLocker = autoLocker
    }

    public var isBioProtected: Bool {
        lockReader.isBioProtected
    }

    public var isPinProtected: Bool {
        lockReader.isPinProtected
    }

    public var autolockerTimeout: LockTime {
        autoLocker.autolockerTimeout
    }

    public func activatePin(pin: String, completion: @escaping (Bool) -> Void) {
        pinLocker.activatePin(pin: pin, completion: completion)
    }

    public func deactivatePin(completion: @escaping (Bool) -> Void) {
        pinLocker.deactivatePin(completion: completion)
    }

    public func activateBio(completion: @escaping (Bool) -> Void) {
        bioLocker.activateBio(completion: completion)
    }

    public func deactivateBio(completion: @escaping (Bool) -> Void) {
        bioLocker.deactivateBio(completion: completion)
    }

    public func setAutolockerTimeout(_ timeout: LockTime) {
        self.autoLocker.setAutolockerTimeout(timeout)
    }
}
