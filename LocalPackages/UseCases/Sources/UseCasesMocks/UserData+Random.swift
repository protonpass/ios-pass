//
// UserData+Random.swift
// Proton Pass - Created on 02/01/2025.
// Copyright (c) 2025 Proton Technologies AG
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
//

import ProtonCoreLogin

public extension UserData {
    static func random() -> UserData {
        UserData(credential: .init(sessionID: .random(),
                                accessToken: .random(),
                                refreshToken: .random(),
                                userName: .random(),
                                userID: .random(),
                                privateKey: .random(),
                                passwordKeySalt: .random()),
              user: .init(ID: .random(),
                          name: .random(),
                          usedSpace: .random(in: 0...100),
                          usedBaseSpace: .random(in: 0...100),
                          usedDriveSpace: .random(in: 0...100),
                          currency: .random(),
                          credit: .random(in: 0...100),
                          maxSpace: .random(in: 0...100),
                          maxBaseSpace: .random(in: 0...100),
                          maxDriveSpace: .random(in: 0...100),
                          maxUpload: .random(in: 0...100),
                          role: .random(in: 0...100),
                          private: .random(in: 0...100),
                          subscribed: .vpn,
                          services: .random(in: 0...100),
                          delinquent: .random(in: 0...100),
                          orgPrivateKey: .random(),
                          email: .random(),
                          displayName: .random(),
                          keys: []),
              salts: [],
              passphrases: [:],
              addresses: [],
              scopes: [])
    }
}
