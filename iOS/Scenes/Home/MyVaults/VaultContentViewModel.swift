//
// VaultContentViewModel.swift
// Proton Pass - Created on 21/07/2022.
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
import ProtonCore_UIFoundations
import UIComponents
import UIKit

protocol VaultContentViewModelDelegate: AnyObject {
    func vaultContentViewModelWantsToToggleSidebar()
    func vaultContentViewModelWantsToSearch()
    func vaultContentViewModelWantsToCreateNewItem()
    func vaultContentViewModelWantsToCreateNewVault()
}

final class VaultContentViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    private let vaultSelection: VaultSelection

    var selectedVault: VaultProtocol? { vaultSelection.selectedVault }
    var vaults: [VaultProtocol] { vaultSelection.vaults }

    @Published private(set) var items: [ItemProtocol] = [DummyItem].preview

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: VaultContentViewModelDelegate?

    init(vaultSelection: VaultSelection) {
        self.vaultSelection = vaultSelection
        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func update(selectedVault: VaultProtocol?) {
        vaultSelection.update(selectedVault: selectedVault)
    }
}

// MARK: - Actions
extension VaultContentViewModel {
    func toggleSidebarAction() {
        delegate?.vaultContentViewModelWantsToToggleSidebar()
    }

    func searchAction() {
        delegate?.vaultContentViewModelWantsToSearch()
    }

    func createItemAction() {
        delegate?.vaultContentViewModelWantsToCreateNewItem()
    }

    func createVaultAction() {
        delegate?.vaultContentViewModelWantsToCreateNewVault()
    }
}

// MARK: - Previews
struct DummyItemMetadata: ItemMetadataProtocol {
    let name: String
    let note: String
}

struct DummyItemAlias: ItemAliasProtocol {}

struct DummyItemNote: ItemNoteProtocol {}

struct DummyItemLogin: ItemLoginProtocol {
    public let username: String
    public let password: String
    public let urls: [String]
}

struct DummyItem: ItemProtocol {
    public let itemContent: ItemContent
    public let itemMetadata: ItemMetadataProtocol
}

extension DummyItem {
    static var login1: DummyItem {
        let metadata = DummyItemMetadata(name: "Amazon",
                                         note: "Used for UK & French Amazon")
        let login = DummyItemLogin(username: "adam.smith@proton.me",
                                   password: "12345678",
                                   urls: ["https://amazon.co.uk", "https://amazon.fr"])
        return .init(itemContent: .login(login),
                     itemMetadata: metadata)
    }

    static var login2: DummyItem {
        let metadata = DummyItemMetadata(name: "LinkedIn",
                                         note: "Used for LinkedIn")
        let login = DummyItemLogin(username: "john.doe@proton.me",
                                   password: "aaaaaaaa",
                                   urls: ["https://linkedin.com"])
        return .init(itemContent: .login(login),
                     itemMetadata: metadata)
    }

    static var alias1: DummyItem {
        let metadata = DummyItemMetadata(name: "Alias for newsletter",
                                         note: "Used for newsletter")
        return .init(itemContent: .alias, itemMetadata: metadata)
    }

    static var alias2: DummyItem {
        let metadata = DummyItemMetadata(name: "Alias for online gaming",
                                         note: "Used for online gaming")
        return .init(itemContent: .alias, itemMetadata: metadata)
    }

    static var alias3: DummyItem {
        let metadata = DummyItemMetadata(name: "Alias for online shopping",
                                         note: "Used for online shopping")
        return .init(itemContent: .alias, itemMetadata: metadata)
    }

    static var note1: DummyItem {
        let metadata = DummyItemMetadata(name: "Cooking recipes",
                                         note: "Best Vietnamese recipes")
        return .init(itemContent: .note, itemMetadata: metadata)
    }

    static var note2: DummyItem {
        let metadata = DummyItemMetadata(name: "Places to visit in France",
                                         note: "Best places to visit in France")
        return .init(itemContent: .note, itemMetadata: metadata)
    }
}

extension Array where Element == DummyItem {
    static var preview: [Element] {
        [DummyItem.login1,
         DummyItem.alias1,
         DummyItem.note1,
         DummyItem.login2,
         DummyItem.alias2,
         DummyItem.note2,
         DummyItem.alias3]
    }
}

extension ItemProtocol {
    func toGenericItem() -> GenericItem {
        let icon: UIImage
        switch itemContent {
        case .alias:
            icon = IconProvider.alias
        case .note:
            icon = IconProvider.note
        case .login:
            icon = IconProvider.keySkeleton
        }

        let detail: String?
        switch itemContent {
        case .alias:
            detail = itemMetadata.note
        case .note:
            detail = nil
        case .login(let login):
            detail = login.username
        }

        return .init(icon: icon, title: itemMetadata.name, detail: detail)
    }
}
