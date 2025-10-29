//
// GeneratePasswordCoordinator.swift
// Proton Pass - Created on 09/05/2023.
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

import Core
import Entities
import Macro
import SwiftUI

enum GeneratePasswordViewMode {
    /// View is shown as part of create login process
    case createLogin
    /// View is shown indepently without any context
    case random
}

enum PasswordType: Int, CaseIterable {
    case random = 0, memorable
}

@MainActor
protocol GeneratePasswordCoordinatorDelegate: AnyObject {
    func generatePasswordCoordinatorWantsToPresent(viewController: UIViewController)
}

@MainActor
final class GeneratePasswordCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private weak var generatePasswordViewModelDelegate: (any GeneratePasswordViewModelDelegate)?
    private let mode: GeneratePasswordViewMode
    weak var delegate: (any GeneratePasswordCoordinatorDelegate)?
    private var sheetPresentationController: UISheetPresentationController?

    init(generatePasswordViewModelDelegate: (any GeneratePasswordViewModelDelegate)?,
         mode: GeneratePasswordViewMode) {
        self.generatePasswordViewModelDelegate = generatePasswordViewModelDelegate
        self.mode = mode
    }

    func start() {
        guard let delegate else {
            assertionFailure("GeneratePasswordCoordinatorDelegate is not set")
            return
        }

        let viewModel = GeneratePasswordViewModel(mode: mode)
        viewModel.delegate = generatePasswordViewModelDelegate
        viewModel.uiDelegate = self
        let view = GeneratePasswordView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.sheetPresentationController?.prefersGrabberVisible = true

        sheetPresentationController = viewController.sheetPresentationController
        updateSheetHeight(isShowingAdvancedOptions: viewModel.isShowingAdvancedOptions)

        delegate.generatePasswordCoordinatorWantsToPresent(viewController: viewController)
    }
}

// MARK: - Private APIs

extension GeneratePasswordCoordinator {
    func updateSheetHeight(isShowingAdvancedOptions: Bool) {
        guard let sheetPresentationController else {
            assertionFailure("sheetPresentationController is null. Coordinator is not yet started.")
            return
        }

        let detent: UISheetPresentationController.Detent
        let detentIdentifier: UISheetPresentationController.Detent.Identifier

        let makeCustomDetent: (Int) -> UISheetPresentationController.Detent = { height in
            UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
        }
        detent = makeCustomDetent(isShowingAdvancedOptions ? 500 : 400)
        detentIdentifier = detent.identifier

        sheetPresentationController.animateChanges {
            sheetPresentationController.detents = [detent]
            sheetPresentationController.selectedDetentIdentifier = detentIdentifier
        }
    }
}

// MARK: - GeneratePasswordViewModelUiDelegate

extension GeneratePasswordCoordinator: GeneratePasswordViewModelUiDelegate {
    func generatePasswordViewModelWantsToUpdateSheetHeight(isShowingAdvancedOptions: Bool) {
        updateSheetHeight(isShowingAdvancedOptions: isShowingAdvancedOptions)
    }
}

extension GeneratePasswordViewMode {
    var confirmTitle: String {
        switch self {
        case .createLogin:
            #localized("Confirm")
        case .random:
            #localized("Copy and close")
        }
    }
}

extension PasswordType {
    var title: String {
        switch self {
        case .random:
            #localized("Random password")
        case .memorable:
            #localized("Memorable password")
        }
    }
}

extension WordSeparator {
    var title: String {
        switch self {
        case .hyphens:
            #localized("Hyphens")
        case .spaces:
            #localized("Spaces")
        case .periods:
            #localized("Periods")
        case .commas:
            #localized("Commas")
        case .underscores:
            #localized("Underscores")
        case .numbers:
            #localized("Numbers")
        case .numbersAndSymbols:
            #localized("Numbers and Symbols")
        }
    }
}
