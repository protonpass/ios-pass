//
// UserData+Codable.swift
// Proton Pass - Created on 15/07/2022.
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

import ProtonCoreDataModel
import ProtonCoreLogin
import ProtonCoreNetworking

extension UserData: Codable {
    private enum CodingKeys: String, CodingKey {
        case credential
        case user
        case salts
        case passphrases
        case addresses
        case scopes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(credential: container.decode(AuthCredential.self, forKey: .credential),
                      user: container.decode(User.self, forKey: .user),
                      salts: container.decode([KeySalt].self, forKey: .salts),
                      passphrases: container.decode([String: String].self, forKey: .passphrases),
                      addresses: container.decode([Address].self, forKey: .addresses),
                      scopes: container.decode([String].self, forKey: .scopes))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credential, forKey: .credential)
        try container.encode(user, forKey: .user)
        try container.encode(salts, forKey: .salts)
        try container.encode(passphrases, forKey: .passphrases)
        try container.encode(addresses, forKey: .addresses)
        try container.encode(scopes, forKey: .scopes)
    }
}

public extension UserData {
    // periphery:ignore
    static var preview: UserData {
        let credential = AuthCredential(sessionID: .random(),
                                        accessToken: .random(),
                                        refreshToken: .random(),
                                        userName: .random(),
                                        userID: .random(),
                                        privateKey: nil,
                                        passwordKeySalt: nil)

        let user = User(ID: .random(),
                        name: nil,
                        usedSpace: 0,
                        usedBaseSpace: 0,
                        usedDriveSpace: 0,
                        currency: "",
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
                        keys: [],
                        flags: .init(hasBYOEAddress: false,
                                     hasTemporaryPassword: false,
                                     sso: false))

        return .init(credential: credential,
                     user: user,
                     salts: [],
                     passphrases: [:],
                     addresses: [],
                     scopes: [])
    }
}
