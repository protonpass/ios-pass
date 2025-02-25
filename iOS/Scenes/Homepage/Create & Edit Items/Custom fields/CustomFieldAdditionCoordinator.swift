//
// CustomFieldAdditionCoordinator.swift
// Proton Pass - Created on 10/05/2023.
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
import DesignSystem
import Entities
import Factory
import Macro
import SwiftUI

@MainActor
protocol CustomFieldAdditionDelegate: AnyObject {
    func customFieldAdded(_ customField: CustomField)
}

@MainActor
final class CustomFieldAdditionCoordinator: DeinitPrintable, CustomCoordinator {
    deinit { print(deinitMessage) }

    weak var rootViewController: UIViewController?
    weak var delegate: (any CustomFieldAdditionDelegate)?
    private let shouldShowTotp: Bool

    init(rootViewController: UIViewController,
         delegate: any CustomFieldAdditionDelegate,
         shouldShowTotp: Bool) {
        self.rootViewController = rootViewController
        self.delegate = delegate
        self.shouldShowTotp = shouldShowTotp
    }

    func start() {
        let view = CustomFieldTypesView(shouldShowTotp: shouldShowTotp) { [weak self] type in
            guard let self else { return }
            rootViewController?.topMostViewController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                let alert = makeAlert(for: type)
                rootViewController?.topMostViewController.present(alert, animated: true)
            }
        }
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.medium.value) * CustomFieldType.cases(shouldShowTotp).count
        if let rootViewController {
            viewController.setDetentType(.custom(CGFloat(customHeight)),
                                         parentViewController: rootViewController)
        }

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        rootViewController?.topMostViewController.present(viewController, animated: true)
    }
}

private extension CustomFieldAdditionCoordinator {
    func makeAlert(for type: CustomFieldType) -> UIAlertController {
        let alert = UIAlertController(title: #localized("Enter a field name"),
                                      message: type.alertMessage,
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = type.placeholder
            let action = UIAction { _ in
                alert.actions.first?.isEnabled = textField.text?.isEmpty == false
            }
            textField.addAction(action, for: .editingChanged)
        }

        let addAction = UIAlertAction(title: #localized("Add"), style: .default) { [weak self] _ in
            guard let self else { return }
            delegate?.customFieldAdded(.init(title: alert.textFields?.first?.text ?? "",
                                             type: type,
                                             content: ""))
        }
        addAction.isEnabled = false
        alert.addAction(addAction)

        let cancelAction = UIAlertAction(title: #localized("Cancel"), style: .cancel)
        alert.addAction(cancelAction)
        return alert
    }
}

private extension CustomFieldType {
    var alertMessage: String {
        switch self {
        case .text:
            #localized("Text custom field")
        case .totp:
            #localized("2FA secret key (TOTP) custom field")
        case .hidden:
            #localized("Hidden custom field")
        case .timestamp:
            #localized("Date custom field")
        }
    }

    var placeholder: String {
        switch self {
        case .text:
            #localized("E.g., User ID, Acct number")
        case .totp:
            #localized("2FA secret key (TOTP)")
        case .hidden:
            #localized("E.g., Recovery key, PIN")
        case .timestamp:
            #localized("Date")
        }
    }
}
