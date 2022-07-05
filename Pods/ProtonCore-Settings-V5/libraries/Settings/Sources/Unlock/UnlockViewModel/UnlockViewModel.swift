//
//  UnlockViewModel.swift
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

protocol BiometricUnlockViewModel {
    var biometryType: BiometryType { get }

    func unlockWithBio()
}

protocol PinUnlockViewModel {
    var onPinUnlockFailure: (() -> Void)? { get set }

    func unlockWithPin(_ pin: String)
}

public class UnlockViewModel: BiometricUnlockViewModel, PinUnlockViewModel {
    typealias Password = UnlockModel.Password

    let bioUnlocker: BioUnlocker
    let pinUnlocker: PinUnlocker
    let lockReader: LockReader
    let logoutManager: LogoutManager?
    let biometryType: BiometryType
    let header: ProtonHeaderViewModel
    let alertSubtitle: String

    var onShouldDismissScreen: (() -> Void)?
    var onPinUnlockFailure: (() -> Void)?

    public init(bioUnlocker: BioUnlocker,
                pinUnlocker: PinUnlocker,
                lockReader: LockReader,
                logout: LogoutManager?,
                biometricType: BiometryType,
                header: ProtonHeaderViewModel,
                alertSubtitle: String) {
        self.bioUnlocker = bioUnlocker
        self.pinUnlocker = pinUnlocker
        self.lockReader = lockReader
        self.logoutManager = logout
        self.biometryType = biometricType
        self.header = header
        self.alertSubtitle = alertSubtitle
    }

    public var allowsSignOut: Bool {
        logoutManager != nil
    }

    public var unlockViewType: PMLockSecurityViewModel {
        let lock = try? lockReader.getLockMode()
        let biometry = BiometryType.currentType
        switch (lock, biometry) {
        case (.pin?, _):
            return .pin
        case (.bio?, .touch), (.bio?, .face):
            return .bio(.touch)
        case (.mix, .touch), (.mix, .face):
            return .mix(.face)
        default:
            return .none
        }
    }

    public func signOut() {
        logoutManager?.logout { [weak self] result in
            switch result {
            case .success: self?.onShouldDismissScreen?()
            case .failure: break
            }
        }
    }

    public func unlockWithBio() {
        bioUnlocker.bioUnlock { [weak self] success in
            guard success else { return }
            self?.onShouldDismissScreen?()
        }
    }

    public func unlockWithPin(_ pin: String) {
        pinUnlocker.pinUnlock(pin: pin) { [weak self] success in
            success ? self?.onShouldDismissScreen?() : self?.onPinUnlockFailure?()
        }
    }
}
