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

    @Published private(set) var items: [ItemContentProtocol] =
    [DummyItemContent].preview

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
struct DummyItemContentMetadata: ItemContentMetadataProtocol {
    let name: String
    let note: String
}

struct DummyItemContentLogin: ItemContentLoginProtocol {
    public let username: String
    public let password: String
    public let urls: [String]
}

struct DummyItemContent: ItemContentProtocol {
    public let itemContentMetadata: ItemContentMetadataProtocol
    public let itemContentData: ItemContentData
}

extension DummyItemContent {
    static var login1: DummyItemContent {
        let metadata = DummyItemContentMetadata(name: "Amazon",
                                                note: "Used for UK & French Amazon")
        let login = DummyItemContentLogin(username: "adam.smith@proton.me",
                                          password: "12345678",
                                          urls: ["https://amazon.co.uk", "https://amazon.fr"])
        return .init(itemContentMetadata: metadata, itemContentData: .login(login))
    }

    static var login2: DummyItemContent {
        let metadata = DummyItemContentMetadata(name: "LinkedIn",
                                                note: "Used for LinkedIn")
        let login = DummyItemContentLogin(username: "john.doe@proton.me",
                                          password: "aaaaaaaa",
                                          urls: ["https://linkedin.com"])
        return .init(itemContentMetadata: metadata, itemContentData: .login(login))
    }

    static var alias1: DummyItemContent {
        let metadata = DummyItemContentMetadata(name: "Alias for newsletter",
                                                note: "Used for newsletter")
        return .init(itemContentMetadata: metadata, itemContentData: .alias)
    }

    static var alias2: DummyItemContent {
        let metadata = DummyItemContentMetadata(name: "Alias for online gaming",
                                                note: "Used for online gaming")
        return .init(itemContentMetadata: metadata, itemContentData: .alias)
    }

    static var alias3: DummyItemContent {
        let metadata = DummyItemContentMetadata(name: "Alias for online shopping",
                                                note: "Used for online shopping")
        return .init(itemContentMetadata: metadata, itemContentData: .alias)
    }

    static var note1: DummyItemContent {
        let metadata = DummyItemContentMetadata(name: "Cooking recipes",
                                                note: "Best Vietnamese recipes")
        return .init(itemContentMetadata: metadata, itemContentData: .note)
    }

    static var note2: DummyItemContent {
        let metadata = DummyItemContentMetadata(name: "Places to visit in France",
                                                note: "Best places to visit in France")
        return .init(itemContentMetadata: metadata, itemContentData: .note)
    }
}

extension Array where Element == DummyItemContent {
    static var preview: [Element] {
        [DummyItemContent.login1,
         DummyItemContent.alias1,
         DummyItemContent.note1,
         DummyItemContent.login2,
         DummyItemContent.alias2,
         DummyItemContent.note2,
         DummyItemContent.alias3]
    }
}

extension ItemContentProtocol {
    func toGenericItem() -> GenericItem {
        let icon: UIImage
        switch itemContentData {
        case .alias:
            icon = IconProvider.alias
        case .note:
            icon = IconProvider.note
        case .login:
            icon = IconProvider.keySkeleton
        }

        let detail: String?
        switch itemContentData {
        case .alias:
            detail = itemContentMetadata.note
        case .note:
            detail = nil
        case .login(let login):
            detail = login.username
        }

        return .init(icon: icon, title: itemContentMetadata.name, detail: detail)
    }
}
