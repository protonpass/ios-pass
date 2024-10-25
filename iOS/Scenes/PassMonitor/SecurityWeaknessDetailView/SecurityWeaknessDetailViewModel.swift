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

typealias SecuritySectionedData = [SecuritySectionHeaderKey: [ItemUiModel]]

extension SecuritySectionedData {
    var isEmpty: Bool {
        values.flatMap { $0 }.isEmpty
    }
}

@MainActor
final class SecurityWeaknessDetailViewModel: ObservableObject, Sendable {
    @Published private(set) var state: FetchableObject<SecuritySectionedData> = .fetching

    let type: SecurityWeakness

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\UseCasesContainer.getAllSecurityAffectedLogins) private var getAllSecurityAffectedLogins
    @LazyInjected(\SharedUseCasesContainer.addTelemetryEvent) private var addTelemetryEvent
    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository

    private var cancellables = Set<AnyCancellable>()

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

    func showDetail(item: any ItemIdentifiable) {
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                                itemId: item.itemId) else {
                    return
                }
                router.present(for: .itemDetail(itemContent, automaticDisplay: false, showSecurityIssues: true))
                let eventType: TelemetryEventType? = switch type {
                case .weakPasswords:
                    .monitorItemDetailFromWeakPassword
                case .missing2FA:
                    .monitorItemDetailFromMissing2FA
                case .reusedPasswords:
                    .monitorItemDetailFromReusedPassword
                default:
                    nil
                }
                if let eventType {
                    addTelemetryEvent(with: eventType)
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
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
                if case let .failure(error) = completion {
                    state = .error(error)
                }
            } receiveValue: { [weak self] logins in
                guard let self else {
                    return
                }

                var data = SecuritySectionedData()

                for (key, value) in logins {
                    data[key.toSecuritySectionHeaderKey] = value
                }
                state = .fetched(data)
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
