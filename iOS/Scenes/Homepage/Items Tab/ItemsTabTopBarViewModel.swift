//
// ItemsTabTopBarViewModel.swift
// Proton Pass - Created on 30/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import DesignSystem
import Entities
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import SwiftUI

extension VaultSelection {
    var accessibilityLabel: String {
        switch self {
        case .all:
            #localized("Show all vaults")
        case let .precise(vault):
            #localized("Show %@ vault", vault.vaultName ?? "")
        case .trash:
            #localized("Show trash")
        case .sharedByMe:
            #localized("Show shared by me")
        case .sharedWithMe:
            #localized("Show shared with me")
        }
    }
}

enum ExtraBulkActionOption {
    case pin
    case unpin
    case disableAliases
    case enableAliases

    var title: LocalizedStringKey {
        switch self {
        case .pin:
            "Pin"
        case .unpin:
            "Unpin"
        case .disableAliases:
            "Disable aliases"
        case .enableAliases:
            "Enable aliases"
        }
    }

    var icon: UIImage {
        switch self {
        case .pin:
            PassIcon.pinAngled
        case .unpin:
            PassIcon.pinAngledSlash
        case .disableAliases:
            PassIcon.aliasSlash
        case .enableAliases:
            IconProvider.alias
        }
    }
}

@MainActor
final class ItemsTabTopBarViewModel: ObservableObject {
    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let currentSelectedItems = resolve(\DataStreamContainer.currentSelectedItems)
    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var actionsDisabled = true
    @Published private(set) var extraOptions: [ExtraBulkActionOption] = []
    @Published private(set) var plan: Plan?

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    var selectedItemsCount: Int {
        currentSelectedItems.value.count
    }

    var vaultSelection: VaultSelection {
        appContentManager.vaultSelection
    }

    var highlighted: Bool {
        !appContentManager.filterOption.isDefault || !selectedSortType.isDefault
    }

    var shouldUpsell: Bool {
        plan?.shouldUpsell ?? false
    }

    var selectable: Bool {
        switch appContentManager.vaultSelection {
        case .all, .sharedByMe, .sharedWithMe, .trash:
            true
        case let .precise(vault):
            vault.canEdit
        }
    }

    var selectedFilterOption: ItemTypeFilterOption {
        appContentManager.filterOption
    }

    var itemCount: ItemCount {
        appContentManager.itemCount
    }

    init() {
        plan = accessRepository.access.value?.access.plan
        appContentManager.attach(to: self, storeIn: &cancellables)
        actionsDisabled = currentSelectedItems.value.isEmpty
        currentSelectedItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                actionsDisabled = items.isEmpty

                extraOptions.removeAll()
                guard vaultSelection != .trash, !items.isEmpty else { return }

                if items.allSatisfy(\.pinned) {
                    extraOptions.append(.unpin)
                } else {
                    extraOptions.append(.pin)
                }

                if items.allSatisfy(\.isAlias) {
                    if items.allSatisfy({ $0.aliasEnabled == false }) {
                        extraOptions.append(.enableAliases)
                    } else {
                        extraOptions.append(.disableAliases)
                    }
                }
            }
            .store(in: &cancellables)

        accessRepository
            .access
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] access in
                guard let self else { return }
                plan = access?.access.plan
            }
            .store(in: &cancellables)
    }

    func upgradeSubscription() {
        router.present(for: .upgradeFlow)
    }
}

extension ItemsTabTopBarViewModel {
    func deselectAllItems() {
        currentSelectedItems.send([])
    }

    func update(_ filterOption: ItemTypeFilterOption) {
        appContentManager.updateItemTypeFilterOption(filterOption)
    }

    func resetFilters() {
        appContentManager.updateItemTypeFilterOption(.all)
        selectedSortType = .mostRecent
    }
}
