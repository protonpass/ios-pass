//
//
// DetailHistoryViewModel.swift
// Proton Pass - Created on 11/01/2024.
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
//

import Combine
import Entities
import Factory
import Foundation
import Macro

enum SelectedRevision {
    case current, past
}

@MainActor
final class DetailHistoryViewModel: ObservableObject, Sendable {
    @Published var selectedItemIndex = 0
    @Published private(set) var restoringItem = false
    @Published private(set) var selectedRevision: SelectedRevision = .past

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedRepositoryContainer.shareRepository) private var shareRepository

    private var cancellables = Set<AnyCancellable>()

    let totpManager = resolve(\SharedServiceContainer.totpManager)
    let currentRevision: ItemContent
    let pastRevision: ItemContent

    var selectedRevisionContent: ItemContent {
        switch selectedRevision {
        case .past:
            pastRevision
        case .current:
            currentRevision
        }
    }

    init(currentRevision: ItemContent, pastRevision: ItemContent) {
        self.currentRevision = currentRevision
        self.pastRevision = pastRevision
        setUp()
    }
}

// MARK: Common operations

extension DetailHistoryViewModel {
    func isDifferent(for element: KeyPath<ItemContent, some Hashable>) -> Bool {
        currentRevision[keyPath: element] != pastRevision[keyPath: element]
    }

    func viewPasskey(_ passkey: Passkey) {
        router.present(for: .passkeyDetail(passkey))
    }

    func restore() {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                restoringItem = false
            }
            restoringItem = true
            do {
                let userId = try await userManager.getActiveUserId()
                guard let share = try await shareRepository.getShare(shareId: currentRevision.shareId) else {
                    return
                }
                let protobuff = ItemContentProtobuf(name: pastRevision.name,
                                                    note: pastRevision.note,
                                                    itemUuid: pastRevision.itemUuid,
                                                    data: pastRevision.contentData,
                                                    customFields: pastRevision.customFields)
                try await itemRepository.updateItem(userId: userId,
                                                    oldItem: currentRevision.item,
                                                    newItemContent: protobuff,
                                                    shareId: currentRevision.shareId,
                                                    isSharedItem: !share.isVaultRepresentation)
                router.present(for: .restoreHistory)
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

// MARK: Copy functions

extension DetailHistoryViewModel {
    func copyValueToClipboard(value: String, message: String) {
        router.action(.copyToClipboard(text: value, message: #localized("%@ copied", message)))
    }

    func copyAlias() {
        copy(\.aliasEmail, message: #localized("Alias copied"))
    }

    func copyEmail() {
        copy(\.loginItem?.email, message: #localized("Email address copied"))
    }

    func copyItemUsername() {
        copy(\.loginItem?.username, message: #localized("Username copied"))
    }

    func copyPassword() {
        copy(\.loginItem?.password, message: #localized("Password copied"))
    }

    func copyTotpToken(_ token: String) {
        copy(token, message: #localized("TOTP copied"))
    }

    func copyCardholderName() {
        copy(\.creditCardItem?.cardholderName, message: #localized("Cardholder name copied"))
    }

    func copyCardNumber() {
        copy(\.creditCardItem?.number, message: #localized("Card number copied"))
    }

    func copyExpirationDate() {
        copy(\.creditCardItem?.displayedExpirationDate, message: #localized("Expiration date copied"))
    }

    func copySecurityCode() {
        copy(\.creditCardItem?.verificationNumber, message: #localized("Security code copied"))
    }
}

// MARK: Private APIs

private extension DetailHistoryViewModel {
    func setUp() {
        $selectedItemIndex
            .receive(on: DispatchQueue.main)
            .sink { [weak self] index in
                guard let self else {
                    return
                }
                selectedRevision = index == 0 ? .past : .current

                if let totpUri = selectedRevisionContent.loginItem?.totpUri {
                    totpManager.bind(uri: totpUri)
                }
            }
            .store(in: &cancellables)
    }

    /// Copy the text to clipboard if it's not empty and show a toast message
    func copy(_ text: String?, message: String) {
        if let text, !text.isEmpty {
            router.action(.copyToClipboard(text: text, message: message))
        }
    }

    func copy(_ keypath: KeyPath<ItemContent, String?>, message: String) {
        copy(selectedRevisionContent[keyPath: keypath], message: message)
    }
}
