//
//  Locker.swift
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

public typealias Locker = LockReader & PinLocker & BioLocker & AutoLocker
public protocol PinLocker: PinLockActivator, PinLockDeactivator { }
public protocol BioLocker: BioLockActivator, BioLockDeactivator { }

/// A type that is able to stablish PIN protection for the system.
public protocol PinLockActivator {
    func activatePin(pin: String, completion: @escaping (Bool) -> Void)
}

/// A type that is able to remove stablished PIN protection of the system.
public protocol PinLockDeactivator {
    func deactivatePin(completion: @escaping (Bool) -> Void)
}
/// A type that is able to stablish Biometric protection for the system.
public protocol BioLockActivator {
    func activateBio(completion: @escaping (Bool) -> Void)
}

/// A type that is able to remove stablished Biometric protection of the system.
public protocol BioLockDeactivator {
    func deactivateBio(completion: @escaping (Bool) -> Void)
}

/// A type that is able to set Autolock timeout the system.
public protocol AutoLocker: AnyObject {
    var autolockerTimeout: LockTime { get }
    func setAutolockerTimeout(_ timeout: LockTime)
}
