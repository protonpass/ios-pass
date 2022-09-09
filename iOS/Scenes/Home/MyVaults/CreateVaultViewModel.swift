//
// CreateVaultViewModel.swift
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

import Client
import Combine
import Core
import ProtonCore_Login
import SwiftUI

final class CreateVaultViewModel: BaseViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var name = ""
    @Published var note = ""

    private let userData: UserData
    private let shareRepository: ShareRepositoryProtocol

    var onCreatedShare: ((Share) -> Void)?

    init(userData: UserData,
         shareRepository: ShareRepositoryProtocol) {
        self.userData = userData
        self.shareRepository = shareRepository
        super.init()
    }

    func createVault() {
        Task { @MainActor in
            do {
                isLoading = true
                let addressKey = userData.getAddressKey()
                let createVaultRequest = try CreateVaultRequest(addressKey: addressKey,
                                                                name: name,
                                                                description: note)
                let createdShare =
                try await shareRepository.createVault(request: createVaultRequest)
                isLoading = false
                onCreatedShare?(createdShare)
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
}
