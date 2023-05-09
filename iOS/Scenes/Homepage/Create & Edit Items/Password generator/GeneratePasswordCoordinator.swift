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
import SwiftUI
import UIKit

enum GeneratePasswordViewMode {
    /// View is shown as part of create login process
    case createLogin
    /// View is shown indepently without any context
    case random

    var confirmTitle: String {
        switch self {
        case .createLogin:
            return "Confirm"
        case .random:
            return "Copy and close"
        }
    }
}

enum PasswordType: CaseIterable {
    case random, memorable

    var title: String {
        switch self {
        case .random:
            return "Random Password"
        case .memorable:
            return "Memorable Password"
        }
    }
}

enum MemorablePasswordMode {
    case regular, advanced
}

protocol GeneratePasswordCoordinatorDelegate: AnyObject {
    func generatePasswordCoordinatorWantsToPresent(viewController: UIViewController)
}

final class GeneratePasswordCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private weak var generatePasswordViewModelDelegate: GeneratePasswordViewModelDelegate?
    private let mode: GeneratePasswordViewMode
    weak var delegate: GeneratePasswordCoordinatorDelegate?

    private var generatePasswordViewModel: GeneratePasswordViewModel?
    private var sheetPresentationController: UISheetPresentationController?

    init(generatePasswordViewModelDelegate: GeneratePasswordViewModelDelegate?,
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

        generatePasswordViewModel = viewModel
        sheetPresentationController = viewController.sheetPresentationController
        updateSheetHeight(passwordType: viewModel.type, memorablePasswordMode: viewModel.memorableMode)

        delegate.generatePasswordCoordinatorWantsToPresent(viewController: viewController)
    }
}

// MARK: - Private APIs
extension GeneratePasswordCoordinator {
    func updateSheetHeight(passwordType: PasswordType, memorablePasswordMode: MemorablePasswordMode) {
        guard let sheetPresentationController else {
            assertionFailure("sheetPresentationController is null. Coordinator is not yet started.")
            return
        }

        let detent: UISheetPresentationController.Detent
        let detentIdentifier: UISheetPresentationController.Detent.Identifier

        if #available(iOS 16, *) {
            let makeCustomDetent: (Int) -> UISheetPresentationController.Detent = { height in
                UISheetPresentationController.Detent.custom { _ in
                    CGFloat(height)
                }
            }

            switch passwordType {
            case .random:
                detent = makeCustomDetent(344)
            case .memorable:
                switch memorablePasswordMode {
                case .regular:
                    detent = makeCustomDetent(500)
                case .advanced:
                    detent = makeCustomDetent(750)
                }
            }

            detentIdentifier = detent.identifier
        } else {
            switch passwordType {
            case .random:
                detent = .medium()
                detentIdentifier = .medium
            case .memorable:
                detent = .large()
                detentIdentifier = .large
            }
        }

        sheetPresentationController.animateChanges {
            sheetPresentationController.detents = [detent]
            sheetPresentationController.selectedDetentIdentifier = detentIdentifier
        }
    }
}

// MARK: - GeneratePasswordViewModelUiDelegate
extension GeneratePasswordCoordinator: GeneratePasswordViewModelUiDelegate {
    func generatePasswordViewModelWantsToChangePasswordType(currentType: PasswordType) {
        assert(generatePasswordViewModel != nil, "generatePasswordViewModel is not set")

        let viewModel = PasswordTypesViewModel(selectedType: currentType)
        viewModel.delegate = generatePasswordViewModel

        let view = PasswordTypesView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)

        if #available(iOS 16.0, *) {
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(120)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }

        viewController.sheetPresentationController?.prefersGrabberVisible = true

        delegate?.generatePasswordCoordinatorWantsToPresent(viewController: viewController)
    }

    func generatePasswordViewModelWantsToChangeMemorableMode(currentMode: MemorablePasswordMode) {
        print(#function)
    }

    func generatePasswordViewModelWantsToUpdateSheetHeight(passwordType: PasswordType,
                                                           memorablePasswordMode: MemorablePasswordMode) {
        updateSheetHeight(passwordType: passwordType, memorablePasswordMode: memorablePasswordMode)
    }
}
