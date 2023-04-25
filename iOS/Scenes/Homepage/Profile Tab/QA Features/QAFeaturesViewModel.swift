//
// QAFeaturesViewModel.swift
// Proton Pass - Created on 15/04/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCore_Login

final class QAFeaturesViewModel: ObservableObject {
    let credentialManager: CredentialManagerProtocol
    let favIconRepository: FavIconRepositoryProtocol
    let telemetryEventRepository: TelemetryEventRepositoryProtocol
    let preferences: Preferences
    let bannerManager: BannerManager
    let logManager: LogManager
    let userData: UserData

    init(credentialManager: CredentialManagerProtocol,
         favIconRepository: FavIconRepositoryProtocol,
         telemetryEventRepository: TelemetryEventRepositoryProtocol,
         preferences: Preferences,
         bannerManager: BannerManager,
         logManager: LogManager,
         userData: UserData) {
        self.credentialManager = credentialManager
        self.favIconRepository = favIconRepository
        self.telemetryEventRepository = telemetryEventRepository
        self.preferences = preferences
        self.bannerManager = bannerManager
        self.logManager = logManager
        self.userData = userData
    }
}
