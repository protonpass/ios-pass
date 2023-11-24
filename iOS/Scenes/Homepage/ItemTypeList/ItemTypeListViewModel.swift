//
// ItemTypeListViewModel.swift
// Proton Pass - Created on 22/05/2023.
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
import Core
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import UIKit

enum ItemType: CaseIterable {
    case login, alias, creditCard, note, password
}

extension ItemContentType {
    var type: ItemType {
        switch self {
        case .login:
            .login
        case .alias:
            .alias
        case .creditCard:
            .creditCard
        case .note:
            .note
        }
    }
}

protocol ItemTypeListViewModelDelegate: AnyObject {
    func itemTypeListViewModelDidSelect(type: ItemType)
}

final class ItemTypeListViewModel: ObservableObject {
    @Published private(set) var limitation: AliasLimitation?
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    weak var delegate: ItemTypeListViewModelDelegate?

    init() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.limitation = try await self.upgradeChecker.aliasLimitation()
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func select(type: ItemType) {
        delegate?.itemTypeListViewModelDidSelect(type: type)
    }
}

extension ItemType {
    var icon: UIImage {
        switch self {
        case .login:
            IconProvider.user
        case .alias:
            IconProvider.alias
        case .creditCard:
            PassIcon.passCreditCardOneStripe
        case .note:
            IconProvider.fileLines
        case .password:
            IconProvider.key
        }
    }

    var tintColor: UIColor {
        switch self {
        case .login:
            ItemContentType.login.normMajor2Color
        case .alias:
            ItemContentType.alias.normMajor2Color
        case .creditCard:
            ItemContentType.creditCard.normMajor2Color
        case .note:
            ItemContentType.note.normMajor2Color
        case .password:
            PassColor.passwordInteractionNormMajor2
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .login:
            ItemContentType.login.normMinor1Color
        case .alias:
            ItemContentType.alias.normMinor1Color
        case .creditCard:
            ItemContentType.creditCard.normMinor1Color
        case .note:
            ItemContentType.note.normMinor1Color
        case .password:
            PassColor.passwordInteractionNormMinor1
        }
    }

    var title: String {
        switch self {
        case .login:
            #localized("Login")
        case .alias:
            #localized("Alias")
        case .note:
            #localized("Note")
        case .creditCard:
            #localized("Card")
        case .password:
            #localized("Password")
        }
    }

    var description: String {
        switch self {
        case .login:
            #localized("Add login details for an app or site")
        case .alias:
            #localized("Get an email alias to use on new apps")
        case .creditCard:
            #localized("Securely store your payment information")
        case .note:
            #localized("Jot down a PIN, code, or note to self")
        case .password:
            #localized("Generate a secure password")
        }
    }
}
