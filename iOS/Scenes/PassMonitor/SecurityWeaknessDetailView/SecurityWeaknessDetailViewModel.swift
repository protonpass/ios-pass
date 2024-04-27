//
//
// SecurityWeaknessDetailViewModel.swift
// Proton Pass - Created on 05/03/2024.
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
import UseCases

@MainActor
final class SecurityWeaknessDetailViewModel: ObservableObject, Sendable {
    @Published private(set) var sectionedData = [SecuritySectionHeaderKey: [ItemContent]]()
    @Published private(set) var loading = true

    let type: SecurityWeakness
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let getAllSecurityAffectedLogins = resolve(\UseCasesContainer.getAllSecurityAffectedLogins)
    private var cancellables = Set<AnyCancellable>()

    var showSections: Bool {
        type.hasSections
    }

    var isEmpty: Bool {
        sectionedData.values.flatMap { $0 }.isEmpty
    }

    var nothingWrongMessage: String {
        switch type {
        case .weakPasswords:
            #localized("No weak passwords were found in your login items")
        case .reusedPasswords:
            #localized("You have no reused passwords in your login items")
        case .missing2FA:
            #localized("All your login items have two-factor authentication enabled")
        case .excludedItems:
            #localized("You don't have any excluded login items from monitoring")
        default:
            ""
        }
    }

    init(type: SecurityWeakness) {
        self.type = type
        setUp()
    }

    func showDetail(item: ItemContent) {
        router.present(for: .itemDetail(item, automaticDisplay: false, showSecurityIssues: true))
    }

    func dismiss(isSheet: Bool) {
        router.action(.back(isShownAsSheet: isSheet))
    }
}

private extension SecurityWeaknessDetailViewModel {
    func setUp() {
        getAllSecurityAffectedLogins(for: type)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else {
                    return
                }
                switch completion {
                case .finished:
                    return
                case let .failure(error):
                    router.display(element: .displayErrorBanner(error))
                }
            } receiveValue: { [weak self] logins in
                guard let self else {
                    return
                }
                loading = false

                var data = [SecuritySectionHeaderKey: [ItemContent]]()

                for (key, value) in logins {
                    data[key.toSecuritySectionHeaderKey] = value
                }
                sectionedData = data
            }
            .store(in: &cancellables)
    }
}

private extension SecuritySection {
    var toSecuritySectionHeaderKey: SecuritySectionHeaderKey {
        switch self {
        case let .reusedPasswords(numberOfTime):
            SecuritySectionHeaderKey(title: #localized("Reused %lld times", numberOfTime.numberOfTimeReused))
        case .excludedItems, .missing2fa, .weakPasswords:
            SecuritySectionHeaderKey(title: "")
        }
    }
}

private extension SecurityWeakness {
    var hasSections: Bool {
        switch self {
        case .excludedItems, .missing2FA, .weakPasswords:
            false
        default:
            true
        }
    }
}
