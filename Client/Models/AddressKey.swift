//
// AddressKey.swift
// Proton Pass - Created on 18/07/2022.
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

import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_Login

public struct AddressKey {
    public let addressId: String
    public let key: Key
    public let keyPassphrase: String
}

public enum UserDataError: Error {
    case noAddresses
    case noAddressKeys
    case noPassphrases
    case noUserKeys
}

public extension UserData {
    // To be refactored: https://jira.protontech.ch/browse/PASSBE-201
    func getAddressKey() throws -> AddressKey {
        guard let address = addresses.first else {
            throw UserDataError.noAddresses
        }

        guard let addressKey = address.keys.first else {
            throw UserDataError.noAddressKeys
        }

        guard let userKeyData = user.keys.first?.privateKey.unArmor else {
            throw UserDataError.noUserKeys
        }

        guard let passphrase = passphrases.first else {
            throw UserDataError.noPassphrases
        }

        let keyPassphrase = try addressKey.passphrase(userBinKeys: [userKeyData],
                                                      mailboxPassphrase: passphrase.value)
        return .init(addressId: address.addressID,
                     key: addressKey,
                     keyPassphrase: keyPassphrase)
    }
}
