//
// SideBarViewModel.swift
// Proton Pass - Created on 17/08/2022.
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

protocol SideBarViewModelDelegate: AnyObject {
    func sideBarViewModelWantsToShowUsersSwitcher()
    func sideBarViewModelWantsToHandleItem(_ item: SidebarItem)
    func sideBarViewModelWantsToShowAllItems()
    func sideBarViewModelWantsToShowItems(ofType type: ItemContentType)
}

final class SideBarViewModel: ObservableObject {
    @Published var isShowingDevPreviewsOption: Bool {
        didSet {
            DeveloperModeStateManager.shared.isOn = isShowingDevPreviewsOption
        }
    }
    @Published private(set) var itemCount: ItemCount?
    let user: UserProtocol
    weak var delegate: SideBarViewModelDelegate?

    init(user: UserProtocol) {
        self.user = user
        self.isShowingDevPreviewsOption = DeveloperModeStateManager.shared.isOn
    }

    func userSwitcherAction() {
        delegate?.sideBarViewModelWantsToShowUsersSwitcher()
    }

    func sideBarItemAction(_ item: SidebarItem) {
        delegate?.sideBarViewModelWantsToHandleItem(item)
    }

    func showAllItemsAction() {
        delegate?.sideBarViewModelWantsToShowAllItems()
    }

    func showItemsAction(_ type: ItemContentType) {
        delegate?.sideBarViewModelWantsToShowItems(ofType: type)
    }
}

extension SideBarViewModel: ItemCountDelegate {
    func itemCountDidUpdate(_ itemCount: ItemCount) {
        DispatchQueue.main.async {
            self.itemCount = itemCount
        }
    }
}

extension SideBarViewModel {
    static var preview: SideBarViewModel {
        .init(user: PreviewUserInfo.preview)
    }
}
