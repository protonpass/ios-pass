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

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var name = ""
    @Published var note = ""

    private let userData: UserData
    private let shareRepository: ShareRepositoryProtocol

    private var cancellables = Set<AnyCancellable>()

    var onCreatedShare: ((Share) -> Void)?

    init(userData: UserData,
         shareRepository: ShareRepositoryProtocol) {
        self.userData = userData
        self.shareRepository = shareRepository
        super.init()

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.viewModelBeginsLoading()
                } else {
                    self.delegate?.viewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.viewModelDidFailWithError(error)
                }
            }
            .store(in: &cancellables)
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
