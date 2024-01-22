//
// UserData+Test.swift
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

import Client
import Core
import ProtonCoreDataModel
import ProtonCoreLogin
import ProtonCoreNetworking

extension UserData {
    static var test: UserData {
        // swiftlint:disable force_try
        let (userKey, _) = try! CryptoUtils.generateKey(name: "test", email: "test")
        let userKeyId = String.random()
        let user = User(ID: .random(),
                        name: nil,
                        usedSpace: 0,
                        usedBaseSpace: 0,
                        usedDriveSpace: 0,
                        currency: .random(),
                        credit: 0,
                        maxSpace: 0,
                        maxBaseSpace: 0,
                        maxDriveSpace: 0,
                        maxUpload: 0,
                        role: 0,
                        private: 0,
                        subscribed: [],
                        services: 0,
                        delinquent: 0,
                        orgPrivateKey: nil,
                        email: nil,
                        displayName: nil,
                        keys: [.init(keyID: userKeyId, privateKey: userKey)])

        let (addressKey, addressKeyPassphrase) = try! CryptoUtils.generateKey(name: "test", email: "test")
        let address = Address(addressID: .random(),
                              domainID: nil,
                              email: .random(),
                              send: .active,
                              receive: .active,
                              status: .enabled,
                              type: .protonDomain,
                              order: 0,
                              displayName: .random(),
                              signature: .random(),
                              hasKeys: 0,
                              keys: [.init(keyID: .random(), privateKey: addressKey)])
        return .init(credential: .preview,
                     user: user,
                     salts: [],
                     passphrases: [userKeyId: addressKeyPassphrase],
                     addresses: [address],
                     scopes: [])
    }
}
