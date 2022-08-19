//
// CreateLoginViewModel.swift
// Proton Pass - Created on 05/08/2022.
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
import SwiftUI

protocol CreateLoginViewModelDelegate: AnyObject {
    func createLoginViewModelBeginsLoading()
    func createLoginViewModelStopsLoading()
    func createLoginViewModelWantsToGeneratePassword(delegate: GeneratePasswordViewModelDelegate)
    func createLoginViewModelDidFailWithError(error: Error)
    func createLoginViewModelDidCreateLogin()
}

final class CreateLoginViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var createdLogin = false

    @Published var title = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isPasswordSecure = true // Password in clear text or not
    @Published var urls: [String] = [""]
    @Published var note = ""

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: CreateLoginViewModelDelegate?

    private let shareId: String
    private let addressKey: AddressKey
    private let shareKeysRepository: ShareKeysRepositoryProtocol
    private let itemRevisionRepository: ItemRevisionRepositoryProtocol

    init(shareId: String,
         addressKey: AddressKey,
         shareKeysRepository: ShareKeysRepositoryProtocol,
         itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        self.shareId = shareId
        self.addressKey = addressKey
        self.shareKeysRepository = shareKeysRepository
        self.itemRevisionRepository = itemRevisionRepository

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.createLoginViewModelBeginsLoading()
                } else {
                    self.delegate?.createLoginViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.createLoginViewModelDidFailWithError(error: error)
                }
            }
            .store(in: &cancellables)
    }

    func saveAction() {
        isLoading = true
        Task { @MainActor in
            do {
                let loginData = ItemContentData.login(username: "nhon@proton.black",
                                                      password: "12345678",
                                                      urls: ["https://proton.black"])
                let loginItem = ItemContentProtobuf(name: "Nhon login",
                                                    note: "Login for black",
                                                    data: loginData)

                let shareKeys = try await shareKeysRepository.getShareKeys(shareId: shareId,
                                                                           page: 0,
                                                                           pageSize: .max)
                // swiftlint:disable:next todo
                // TODO: Get latest vault key & item key directly from repository
                // swiftlint:disable:next force_unwrapping
                let latestVaultKey = shareKeys.vaultKeys.max(by: { $0.rotation > $1.rotation })!
                let latestItemKey = shareKeys.itemKeys.first { $0.rotationID == latestVaultKey.rotationID }!
                let request = try CreateItemRequest(vaultKey: latestVaultKey,
                                                    itemKey: latestItemKey,
                                                    addressKey: addressKey,
                                                    itemContent: loginItem)
                try await itemRevisionRepository.createItem(request: request, shareId: shareId)
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }

    @objc
    func generatePasswordAction() {
        delegate?.createLoginViewModelWantsToGeneratePassword(delegate: self)
    }

    func generateAliasAction() {
        let name = String.random(allowedCharacters: [.lowercase], length: 8)
        let host = String.random(allowedCharacters: [.lowercase], length: 5)
        let domain = String.random(allowedCharacters: [.lowercase], length: 5)
        username = "\(name)@\(host).\(domain)"
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension CreateLoginViewModel: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        self.password = password
    }
}
