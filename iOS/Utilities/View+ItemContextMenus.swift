//
// View+ItemContextMenus.swift
// Proton Pass - Created on 18/03/2023.
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
import ProtonCore_UIFoundations
import SwiftUI

enum ItemContextMenu {
    case login(onCopyUsername: () -> Void,
               onCopyPassword: () -> Void,
               onEdit: () -> Void,
               onTrash: () -> Void)

    case alias(onCopyAlias: () -> Void,
               onEdit: () -> Void,
               onTrash: () -> Void)

    case note(onEdit: () -> Void,
              onTrash: () -> Void)

    var sections: [ItemContextMenuOptionSection] {
        let customSection: ItemContextMenuOptionSection?
        let editAndTrashSections: [ItemContextMenuOptionSection]

        switch self {
        case let .login(onCopyUsername, onCopyPassword, onEdit, onTrash):
            customSection = .init(options: [.init(title: "Copy username",
                                                  icon: IconProvider.user,
                                                  action: onCopyUsername),
                                            .init(title: "Copy password",
                                                  icon: IconProvider.key,
                                                  action: onCopyPassword)])
            editAndTrashSections = [.init(options: [.editOption(action: onEdit)]),
                                    .init(options: [.trashOption(action: onTrash)])]

        case let .alias(onCopyAlias, onEdit, onTrash):
            customSection = .init(options: [.init(title: "Copy alias address",
                                                  icon: IconProvider.alias,
                                                  action: onCopyAlias)])
            editAndTrashSections = [.init(options: [.editOption(action: onEdit)]),
                                    .init(options: [.trashOption(action: onTrash)])]

        case let .note(onEdit, onTrash):
            customSection = nil
            editAndTrashSections = [.init(options: [.editOption(action: onEdit)]),
                                    .init(options: [.trashOption(action: onTrash)])]
        }

        return ([customSection] + editAndTrashSections).compactMap { $0 }
    }
}

struct ItemContextMenuOption {
    let title: String
    let icon: UIImage
    let action: () -> Void
    var isDestructive = false

    static func editOption(action: @escaping () -> Void) -> ItemContextMenuOption {
        .init(title: "Edit", icon: IconProvider.pencil, action: action)
    }

    static func trashOption(action: @escaping () -> Void) -> ItemContextMenuOption {
        .init(title: "Move to trash",
              icon: IconProvider.trash,
              action: action,
              isDestructive: true)
    }
}

extension ItemContextMenuOption: Hashable {
    static func == (lhs: ItemContextMenuOption, rhs: ItemContextMenuOption) -> Bool {
        lhs.title == rhs.title && lhs.icon.pngData() == rhs.icon.pngData()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon.pngData())
    }
}

struct ItemContextMenuOptionSection: Hashable {
    let options: [ItemContextMenuOption]
}

private extension View {
    func itemContextMenu(_ menu: () -> ItemContextMenu) -> some View {
        contextMenu {
            ForEach(menu().sections, id: \.hashValue) { section in
                Section {
                    ForEach(section.options, id: \.hashValue) { option in
                        Button(
                            role: option.isDestructive ? .destructive : nil,
                            action: option.action,
                            label: {
                                Label(title: {
                                    Text(option.title)
                                }, icon: {
                                    Image(uiImage: option.icon)
                                })}
                        )
                    }
                }
            }
        }
    }
}

extension View {
    func itemContextMenu(item: ItemTypeIdentifiable,
                         handler: ItemContextMenuHandler) -> some View {
        itemContextMenu {
            switch item.type {
            case .login:
                return .login(onCopyUsername: { handler.copyUsername(item) },
                              onCopyPassword: { handler.copyPassword(item) },
                              onEdit: { handler.edit(item) },
                              onTrash: { handler.trash(item) })
            case .alias:
                return .alias(onCopyAlias: { handler.copyAlias(item) },
                              onEdit: { handler.edit(item) },
                              onTrash: { handler.trash(item) })

            case .note:
                return .note(onEdit: { handler.edit(item) },
                             onTrash: { handler.trash(item) })
            }
        }
    }
}
