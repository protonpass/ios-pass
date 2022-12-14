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

protocol CreateVaultViewModelDelegate: AnyObject {
    func createVaultViewModelDidCreateShare(_ share: Share)
    func createVaultViewModelDidFail(_ error: Error)
}

final class CreateVaultViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isCreating = false
    @Published var name = ""
    @Published var note = ""

    private let userData: UserData
    private let shareRepository: ShareRepositoryProtocol

    weak var delegate: CreateVaultViewModelDelegate?

    var isSaveable: Bool { !name.isEmpty }

    init(userData: UserData,
         shareRepository: ShareRepositoryProtocol) {
        self.userData = userData
        self.shareRepository = shareRepository
    }

    func createVault() {
        Task { @MainActor in
            defer { isCreating = false }
            do {
                isCreating = true
                let addressKey = userData.getAddressKey()
                let createVaultRequest = try CreateVaultRequest(addressKey: addressKey,
                                                                name: name,
                                                                description: note)
                let createdShare =
                try await shareRepository.createVault(request: createVaultRequest)
                delegate?.createVaultViewModelDidCreateShare(createdShare)
            } catch {
                delegate?.createVaultViewModelDidFail(error)
            }
        }
    }
}
