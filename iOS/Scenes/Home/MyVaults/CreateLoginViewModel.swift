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
import Core
import SwiftUI

protocol CreateLoginViewModelDelegate: AnyObject {
    func createLoginViewModelWantsToGeneratePassword(delegate: GeneratePasswordViewModelDelegate)
}

final class CreateLoginViewModel: BaseCreateItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var createdLogin = false

    @Published var title = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isPasswordSecure = true // Password in clear text or not
    @Published var urls: [String] = [""]
    @Published var note = ""

    weak var createLoginDelegate: CreateLoginViewModelDelegate?

    override init(shareId: String,
                  addressKey: AddressKey,
                  shareKeysRepository: ShareKeysRepositoryProtocol,
                  itemRevisionRepository: ItemRevisionRepositoryProtocol) {
        super.init(shareId: shareId,
                   addressKey: addressKey,
                   shareKeysRepository: shareKeysRepository,
                   itemRevisionRepository: itemRevisionRepository)

        $isLoading
            .sink { [weak self] isLoading in
                guard let self = self else { return }
                if isLoading {
                    self.delegate?.createItemViewModelBeginsLoading()
                } else {
                    self.delegate?.createItemViewModelStopsLoading()
                }
            }
            .store(in: &cancellables)

        $error
            .sink { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.delegate?.createItemViewModelDidFailWithError(error)
                }
            }
            .store(in: &cancellables)
    }

    override func itemContentType() -> ItemContentType { .login }

    override func generateItemContent() -> ItemContentProtobuf {
        let loginData = ItemContentData.login(username: "nhon@proton.black",
                                              password: "12345678",
                                              urls: ["https://proton.black"])
        return ItemContentProtobuf(name: "Nhon login",
                                   note: "Login for black",
                                   data: loginData)
    }

    @objc
    func generatePasswordAction() {
        createLoginDelegate?.createLoginViewModelWantsToGeneratePassword(delegate: self)
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
