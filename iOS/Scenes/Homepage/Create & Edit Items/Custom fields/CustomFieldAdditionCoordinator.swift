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

import Client
import Core
import DesignSystem
import Factory
import SwiftUI

protocol CustomFieldAdditionDelegate: AnyObject {
    func customFieldAdded(_ customField: CustomField)
}

final class CustomFieldAdditionCoordinator: DeinitPrintable, CustomCoordinator {
    deinit { print(deinitMessage) }

    private let theme = resolve(\SharedToolingContainer.theme)
    weak var rootViewController: UIViewController!
    let delegate: CustomFieldAdditionDelegate

    init(rootViewController: UIViewController, delegate: CustomFieldAdditionDelegate) {
        self.rootViewController = rootViewController
        self.delegate = delegate
    }

    func start() {
        let view = CustomFieldTypesView { [weak self] type in
            self?.rootViewController.topMostViewController.dismiss(animated: true) { [weak self] in
                guard let self else {
                    return
                }
                let alert = self.makeAlert(for: type)
                self.rootViewController.topMostViewController.present(alert, animated: true)
            }
        }
        let viewController = UIHostingController(rootView: view)

        let customHeight = Int(OptionRowHeight.short.value) * CustomFieldType.allCases.count
        viewController.setDetentType(.custom(CGFloat(customHeight)),
                                     parentViewController: rootViewController)

        viewController.sheetPresentationController?.prefersGrabberVisible = true
        viewController.overrideUserInterfaceStyle = theme.userInterfaceStyle
        rootViewController.topMostViewController.present(viewController, animated: true)
    }
}

private extension CustomFieldAdditionCoordinator {
    func makeAlert(for type: CustomFieldType) -> UIAlertController {
        let alert = UIAlertController(title: "Custom field title".localized,
                                      message: "Enter a title for your custom field".localized,
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Title of the custom field".localized
            let action = UIAction { _ in
                alert.actions.first?.isEnabled = textField.text?.isEmpty == false
            }
            textField.addAction(action, for: .editingChanged)
        }

        let addAction = UIAlertAction(title: "Add".localized, style: .default) { [type, delegate] _ in
            delegate.customFieldAdded(.init(title: alert.textFields?.first?.text ?? "",
                                            type: type,
                                            content: ""))
        }
        addAction.isEnabled = false
        alert.addAction(addAction)

        let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel)
        alert.addAction(cancelAction)
        return alert
    }
}
