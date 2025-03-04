//
// CustomFieldEditionCoordinator.swift
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
import Entities
import Macro
import SwiftUI

struct CustomFieldUiModel: Identifiable, Equatable, Hashable, Sendable {
    var id = UUID().uuidString
    var customField: CustomField
}

extension CustomFieldUiModel {
    func update(title: String? = nil, content: String? = nil) -> CustomFieldUiModel {
        CustomFieldUiModel(id: id,
                           customField: CustomField(title: title ?? customField.title,
                                                    type: customField.type,
                                                    content: content ?? customField.content))
    }
}

struct CustomSectionUiModel: Identifiable, Equatable, Hashable, Sendable {
    var id = UUID().uuidString
    var title: String
    let isCollapsed: Bool
    let fields: [CustomFieldUiModel]

    mutating func rename(_ newTitle: String) {
        title = newTitle
    }
}

@MainActor
protocol CustomFieldEditionDelegate: AnyObject {
    func customFieldEdited(_ uiModel: CustomFieldUiModel, newTitle: String)
}

@MainActor
final class CustomFieldEditionCoordinator: DeinitPrintable, CustomCoordinator {
    deinit { print(deinitMessage) }

    weak var rootViewController: UIViewController!
    let delegate: any CustomFieldEditionDelegate
    let uiModel: CustomFieldUiModel

    init(rootViewController: UIViewController,
         delegate: any CustomFieldEditionDelegate,
         uiModel: CustomFieldUiModel) {
        self.rootViewController = rootViewController
        self.delegate = delegate
        self.uiModel = uiModel
    }

    func start() {
        let alert = UIAlertController(title: #localized("Edit field name"),
                                      message: #localized("Enter new name for « %@ »", uiModel.customField.title),
                                      preferredStyle: .alert)
        alert.addTextField { textField in
            let action = UIAction { _ in
                alert.actions.first?.isEnabled = textField.text?.isEmpty == false
            }
            textField.addAction(action, for: .editingChanged)
        }

        let saveAction = UIAlertAction(title: #localized("Save"), style: .default) { [uiModel, delegate] _ in
            delegate.customFieldEdited(uiModel, newTitle: alert.textFields?.first?.text ?? "")
        }
        saveAction.isEnabled = false
        alert.addAction(saveAction)

        let cancelAction = UIAlertAction(title: #localized("Cancel"), style: .cancel)
        alert.addAction(cancelAction)
        rootViewController.topMostViewController.present(alert, animated: true)
    }
}
