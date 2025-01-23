//
//
// AuthenticatorViewModel.swift
// Proton Pass - Created on 15/03/2024.
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

@MainActor
final class AuthenticatorViewModel: ObservableObject {
    @Published private(set) var displayedItems = [AuthenticatorItem]()
    @Published var searchText = ""

    private let getActiveLoginItems = resolve(\SharedUseCasesContainer.getActiveLoginItems)
    private let generateTotpToken = resolve(\SharedUseCasesContainer.generateTotpToken)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var cancellables = Set<AnyCancellable>()
    private var items = [AuthenticatorItem]()
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    init() {
        setUp()
    }

    func load() async {
        do {
            let userId = try await userManager.getActiveUserId()
            items = try await getActiveLoginItems(userId: userId)
                .compactMap { item in
                    guard let totpUri = item.loginItem?.totpUri,
                          !totpUri.isEmpty, let data = try? generateTotpToken(uri: totpUri) else {
                        return nil
                    }
                    return item.toAuthenticatorItem(totpData: data)
                }

            if displayedItems != items {
                displayedItems = items
            }
        } catch {
            router.display(element: .displayErrorBanner(error))
        }
    }

    func copyTotpToken(_ token: String) {
        router.action(.copyToClipboard(text: token, message: #localized("TOTP copied")))
    }
}

private extension AuthenticatorViewModel {
    func setUp() {
        $searchText
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let self else { return }
                if term.isEmpty {
                    displayedItems = items
                } else {
                    displayedItems = items.filter { item in
                        item.title.lowercased().contains(term.lowercased)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
