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
    case login, alias, note, password, creditCard, identity, custom
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
        case .identity:
            .identity
        case .custom, .sshKey, .wifi:
            .custom
        }
    }
}

@MainActor
final class ItemTypeListViewModel: NSObject, ObservableObject {
    @Published private(set) var limitation: AliasLimitation?
    @Published private(set) var showMoreButton = true
    let onSelect: (ItemType) -> Void

    @LazyInjected(\SharedServiceContainer.upgradeChecker) private var upgradeChecker
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus)
    private var getFeatureFlagStatus

    @MainActor
    enum Mode {
        case hostApp, autoFillExtension

        var shouldShowMoreButton: Bool {
            switch self {
            case .hostApp:
                !UIDevice.current.isIpad
            case .autoFillExtension:
                false
            }
        }
    }

    let mode: Mode

    var supportedTypes: [ItemType] {
        switch mode {
        case .hostApp:
            if getFeatureFlagStatus(for: FeatureFlagType.passCustomTypeV1) {
                ItemType.allCases
            } else {
                ItemType.allCases.filter { $0 != .custom }
            }
        case .autoFillExtension:
            [.login, .alias]
        }
    }

    weak var uiSheetPresentationController: UISheetPresentationController?

    init(mode: Mode,
         onSelect: @escaping (ItemType) -> Void) {
        self.mode = mode
        self.onSelect = onSelect
        super.init()
        Task { [weak self] in
            guard let self else { return }
            do {
                limitation = try await upgradeChecker.aliasLimitation()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func select(type: ItemType) {
        onSelect(type)
    }

    func showMore() {
        guard showMoreButton else {
            return
        }
        uiSheetPresentationController?.animateChanges {
            uiSheetPresentationController?.selectedDetentIdentifier = .large
            showMoreButton = false
        }
    }
}

extension ItemTypeListViewModel: UISheetPresentationControllerDelegate {
    // swiftlint:disable:next line_length
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        showMoreButton = sheetPresentationController.selectedDetentIdentifier == .medium
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
        case .identity:
            IconProvider.cardIdentity
        case .custom:
            IconProvider.pencil
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
        case .identity:
            PassColor.interactionNormMajor2
        case .custom:
            PassColor.textNorm
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
        case .identity:
            PassColor.interactionNormMinor1
        case .custom:
            PassColor.customItemBackground
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
        case .identity:
            #localized("Identity")
        case .custom:
            #localized("Custom item")
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
        case .identity:
            #localized("Fill in your personal data")
        case .custom:
            #localized("Create items with fully customized fields")
        }
    }
}
