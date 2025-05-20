//
// LogInDetailViewModel.swift
// Proton Pass - Created on 07/09/2022.
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
import Entities
import FactoryKit
import Macro
import SwiftUI
import UIKit

@MainActor
final class LogInDetailViewModel: BaseItemDetailViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var passkeys = [Passkey]()
    @Published private(set) var name = ""
    @Published private(set) var email = ""
    @Published private(set) var username = ""
    @Published private(set) var urls: [String] = []
    @Published private(set) var password = ""
    @Published private(set) var totpUri = ""
    @Published private(set) var note = ""
    @Published private(set) var passwordStrength: PasswordStrength?
    @Published private(set) var totpTokenState = TOTPTokenState.loading
    @Published private var aliasItem: SymmetricallyEncryptedItem?
    @Published private(set) var securityIssues: [SecurityWeakness]?
    @Published private(set) var reusedItems: FetchableObject<[ItemContent]> = .fetching

    var isAlias: Bool { aliasItem != nil }
    let showSecurityIssues: Bool

    private let getPasswordStrength = resolve(\SharedUseCasesContainer.getPasswordStrength)
    private let getLoginSecurityIssues = resolve(\UseCasesContainer.getLoginSecurityIssues)
    private let passMonitorRepository = resolve(\SharedRepositoryContainer.passMonitorRepository)

    let totpManager = resolve(\SharedServiceContainer.totpManager)

    private var fetchSimilarPasswordItemsTask: Task<Void, Never>?

    init(isShownAsSheet: Bool,
         itemContent: ItemContent,
         upgradeChecker: any UpgradeCheckerProtocol,
         showSecurityIssues: Bool) {
        self.showSecurityIssues = showSecurityIssues
        super.init(isShownAsSheet: isShownAsSheet,
                   itemContent: itemContent,
                   upgradeChecker: upgradeChecker)
        if showSecurityIssues {
            getLoginSecurityIssues(itemId: itemContent.itemId)
                .subscribe(on: DispatchQueue.global())
                .receive(on: DispatchQueue.main)
                .sink { [weak self] newSecurityIssues in
                    guard let self else {
                        return
                    }
                    securityIssues = newSecurityIssues
                }
                .store(in: &cancellables)

            $securityIssues.receive(on: DispatchQueue.main)
                .sink { [weak self] issues in
                    guard let self, let issues else {
                        return
                    }
                    if issues.contains(.reusedPasswords) {
                        fetchSimilarPasswordItems()
                    }
                }.store(in: &cancellables)
        }
    }

    override func bindValues() {
        super.bindValues()
        if case let .login(data) = itemContent.contentData {
            passkeys = data.passkeys
            name = itemContent.name
            note = itemContent.note
            email = data.email
            username = data.username
            password = data.password
            passwordStrength = getPasswordStrength(password: password)
            urls = data.urls
            totpUri = data.totpUri
            totpManager.bind(uri: data.totpUri)
            getAliasItem(email: data.email, shareId: itemContent.shareId)

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

// MARK: - Private APIs

private extension LogInDetailViewModel {
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
                if try await upgradeChecker.canShowTOTPToken(creationDate: itemContent.item.createTime) {
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

// MARK: - Public actions

extension LogInDetailViewModel {
    func viewPasskey(_ passkey: Passkey) {
        router.present(for: .passkeyDetail(passkey))
    }

    func copyEmail() {
        copyToClipboard(text: email, message: #localized("Email copied"))
    }

    func copyItemUsername() {
        copyToClipboard(text: username, message: #localized("Username copied"))
    }

    func copyPassword() {
        guard !password.isEmpty else { return }
        copyToClipboard(text: password, message: #localized("Password copied"))
    }

    func copyTotpToken(_ token: String) {
        copyToClipboard(text: token, message: #localized("TOTP copied"))
    }

    func showLargePassword() {
        showLarge(.password(password))
    }

    func showAliasDetail() {
        guard let aliasItem else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let symmetricKey = try await getSymmetricKey()
                let itemContent = try aliasItem.getItemContent(symmetricKey: symmetricKey)
                router.present(for: .itemDetail(itemContent,
                                                automaticDisplay: true,
                                                showSecurityIssues: false))
            } catch {
                handle(error)
            }
        }
    }

    func showDetail(for item: ItemContent) {
        router.present(for: .itemDetail(item, automaticDisplay: false))
    }

    func showItemList() {
        router.present(for: .passwordReusedItemList(itemContent))
    }

    func openUrl(_ urlString: String) {
        router.navigate(to: .urlPage(urlString: urlString))
    }

    func fetchSimilarPasswordItems() {
        fetchSimilarPasswordItemsTask?.cancel()
        fetchSimilarPasswordItemsTask = Task { [weak self] in
            guard let self else {
                return
            }
            do {
                reusedItems = .fetching
                let items = try await passMonitorRepository.getItemsWithSamePassword(item: itemContent)
                reusedItems = .fetched(items)
            } catch {
                reusedItems = .error(error)
                handle(error)
            }
        }
    }
}

extension SecurityWeakness {
    var secureRowType: SecureRowType {
        switch self {
        case .excludedItems, .reusedPasswords, .weakPasswords:
            .warning
        case .missing2FA:
            .info
        case .breaches:
            .danger
        }
    }
}
