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
import SwiftUI

protocol CustomFieldAdditionDelegate: AnyObject {
    func customFieldAdded(_ customField: CustomField)
}

final class CustomFieldAdditionCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    let rootViewController: UIViewController
    let preferences: Preferences
    let delegate: CustomFieldAdditionDelegate

    init(rootViewController: UIViewController,
         preferences: Preferences,
         delegate: CustomFieldAdditionDelegate) {
        self.rootViewController = rootViewController
        self.preferences = preferences
        self.delegate = delegate
    }

    func start() {
        let view = CustomFieldTypesView { [rootViewController] type in
            rootViewController.topMostViewController.dismiss(animated: true) { [unowned self] in
                let alert = self.makeAlert(for: type)
                rootViewController.topMostViewController.present(alert, animated: true)
            }
        }
        let viewController = UIHostingController(rootView: view)
        if #available(iOS 16, *) {
            let height = Int(OptionRowHeight.short.value) * CustomFieldType.allCases.count
            let customDetent = UISheetPresentationController.Detent.custom { _ in
                CGFloat(height)
            }
            viewController.sheetPresentationController?.detents = [customDetent]
        } else {
            viewController.sheetPresentationController?.detents = [.medium()]
        }
        viewController.sheetPresentationController?.prefersGrabberVisible = true
        viewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
        rootViewController.topMostViewController.present(viewController, animated: true)
    }
}

private extension CustomFieldAdditionCoordinator {
    func makeAlert(for type: CustomFieldType) -> UIAlertController {
        let alert = UIAlertController(title: "Enter field title",
                                      message: "Custom field \"\(type.title)\"",
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Field title"
            let action = UIAction { _ in
                alert.actions.first?.isEnabled = textField.text?.isEmpty == false
            }
            textField.addAction(action, for: .editingChanged)
        }

        let addAction = UIAlertAction(title: "Add field", style: .default) { [type, delegate] _ in
            delegate.customFieldAdded(.init(title: alert.textFields?.first?.text ?? "",
                                            type: type,
                                            content: ""))
        }
        addAction.isEnabled = false
        alert.addAction(addAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        return alert
    }
}
