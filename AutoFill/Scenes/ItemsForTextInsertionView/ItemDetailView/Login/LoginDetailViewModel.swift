//
// LoginDetailViewModel.swift
// Proton Pass - Created on 09/10/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities
import Factory
import Foundation
import Screens
import UseCases

@MainActor
final class LoginDetailViewModel: BaseItemDetailViewModel {
    @Published private(set) var totpTokenState = TOTPTokenState.loading
    @Published private var aliasItem: SymmetricallyEncryptedItem?
    @Published var selectedAlias: SelectedItem?

    private(set) var email = ""
    private(set) var username = ""
    private(set) var password = ""
    private(set) var urls: [String] = []
    private(set) var totpUri = ""
    private(set) var passkeys = [Passkey]()
    private(set) var passwordStrength: PasswordStrength?

    @LazyInjected(\SharedUseCasesContainer.getPasswordStrength) private var getPasswordStrength
    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\SharedRepositoryContainer.shareRepository) private var shareRepository

    var coloredPassword: AttributedString {
        PasswordUtils.generateColoredPassword(password)
    }

    var isAlias: Bool {
        aliasItem != nil
    }

    override func bindValues() {
        if case let .login(data) = item.content.contentData {
            passkeys = data.passkeys
            email = data.email
            username = data.username
            password = data.password
            passwordStrength = getPasswordStrength(password: password)
            urls = data.urls
            totpUri = data.totpUri
            getAliasItem(email: data.email, shareId: item.vault.shareID)

            if !data.totpUri.isEmpty {
                checkTotpState()
            } else {
                totpTokenState = .allowed
            }
        } else {
            fatalError("Expecting login type")
        }
    }
}

extension LoginDetailViewModel {
    func viewAlias() {
        guard let aliasItem else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                if let alias = try await itemRepository.getItemContent(shareId: aliasItem.shareId,
                                                                       itemId: aliasItem.itemId),
                    let share = try await shareRepository.getDecryptedShare(shareId: alias.shareId) {
                    selectedAlias = .init(userId: item.userId, content: alias, vault: share)
                }
            } catch {
                handle(error)
            }
        }
    }
}

private extension LoginDetailViewModel {
    func getAliasItem(email: String, shareId: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                aliasItem = try await itemRepository.getAliasItem(email: email, shareId: shareId)
            } catch {
                handle(error)
            }
        }
    }

    func checkTotpState() {
        Task { [weak self] in
            guard let self else { return }
            do {
                if try await upgradeChecker.canShowTOTPToken(creationDate: item.content.item.createTime) {
                    totpTokenState = .allowed
                } else {
                    totpTokenState = .notAllowed
                }
            } catch {
                handle(error)
            }
        }
    }
}
