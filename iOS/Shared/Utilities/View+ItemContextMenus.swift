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

import DesignSystem
import Entities
import FactoryKit
import ProtonCoreFeatureFlags
import ProtonCoreUIFoundations
import SwiftUI

// swiftlint:disable enum_case_associated_values_count function_parameter_count
@MainActor
enum ItemContextMenu {
    case login(item: any PinnableItemTypeIdentifiable,
               isEditable: Bool,
               canBeTrashed: Bool,
               onCopyEmail: () -> Void,
               onCopyUsername: () -> Void,
               onCopyPassword: () -> Void,
               onEdit: () -> Void,
               onPinToggle: () -> Void,
               onViewHistory: () -> Void,
               onTrash: () -> Void)

    case alias(item: any PinnableItemTypeIdentifiable,
               isEditable: Bool,
               canBeTrashed: Bool,
               onCopyAlias: () -> Void,
               onToggleAliasStatus: (Bool) -> Void,
               onEdit: () -> Void,
               onPinToggle: () -> Void,
               onViewHistory: () -> Void,
               onTrash: () -> Void)

    case creditCard(item: any PinnableItemTypeIdentifiable,
                    isEditable: Bool,
                    canBeTrashed: Bool,
                    onCopyCardholderName: () -> Void,
                    onCopyCardNumber: () -> Void,
                    onCopyExpirationDate: () -> Void,
                    onCopySecurityCode: () -> Void,
                    onEdit: () -> Void,
                    onPinToggle: () -> Void,
                    onViewHistory: () -> Void,
                    onTrash: () -> Void)

    case note(item: any PinnableItemTypeIdentifiable,
              isEditable: Bool,
              canBeTrashed: Bool,
              onCopyContent: () -> Void,
              onEdit: () -> Void,
              onPinToggle: () -> Void,
              onViewHistory: () -> Void,
              onTrash: () -> Void)

    case identity(item: any PinnableItemTypeIdentifiable,
                  isEditable: Bool,
                  canBeTrashed: Bool,
                  onCopyEmail: () -> Void,
                  onCopyFullname: () -> Void,
                  onEdit: () -> Void,
                  onPinToggle: () -> Void,
                  onViewHistory: () -> Void,
                  onTrash: () -> Void)

    case sshKey(item: any PinnableItemTypeIdentifiable,
                isEditable: Bool,
                canBeTrashed: Bool,
                onEdit: () -> Void,
                onPinToggle: () -> Void,
                onViewHistory: () -> Void,
                onTrash: () -> Void)

    case wifi(item: any PinnableItemTypeIdentifiable,
              isEditable: Bool,
              canBeTrashed: Bool,
              onCopySsid: () -> Void,
              onCopyPassword: () -> Void,
              onEdit: () -> Void,
              onPinToggle: () -> Void,
              onViewHistory: () -> Void,
              onTrash: () -> Void)

    case custom(item: any PinnableItemTypeIdentifiable,
                isEditable: Bool,
                canBeTrashed: Bool,
                onEdit: () -> Void,
                onPinToggle: () -> Void,
                onViewHistory: () -> Void,
                onTrash: () -> Void)

    case trashedItem(isEditable: Bool,
                     onRestore: () -> Void,
                     onPermanentlyDelete: () -> Void)

    var sections: [ItemContextMenuOptionSection] {
        switch self {
        case let .login(item,
                        isEditable,
                        canBeTrashed,
                        onCopyEmail,
                        onCopyUsername,
                        onCopyPassword,
                        onEdit,
                        onPinToggle,
                        onViewHistory,
                        onTrash):
            var sections: [ItemContextMenuOptionSection] = []

            var emailUsernamePasswordOptions = [ItemContextMenuOption]()
            if item.hasEmail {
                emailUsernamePasswordOptions.append(.init(title: "Copy email",
                                                          icon: IconProvider.envelope,
                                                          action: onCopyEmail))
            }

            if item.hasUsername {
                emailUsernamePasswordOptions.append(.init(title: "Copy username",
                                                          icon: IconProvider.user,
                                                          action: onCopyUsername))
            }

            if item.hasPassword {
                emailUsernamePasswordOptions.append(.init(title: "Copy password",
                                                          icon: IconProvider.key,
                                                          action: onCopyPassword))
            }

            sections.append(.init(options: emailUsernamePasswordOptions))

            sections += Self.commonLastSections(item: item,
                                                isEditable: isEditable,
                                                canBeTrashed: canBeTrashed,
                                                onEdit: onEdit,
                                                onPinToggle: onPinToggle,
                                                onViewHistory: onViewHistory,
                                                onTrash: onTrash)

            return sections

        case let .alias(item,
                        isEditable,
                        canBeTrashed,
                        onCopyAlias,
                        onToggleAliasStatus,
                        onEdit,
                        onPinToggle,
                        onViewHistory,
                        onTrash):
            var firstOptions = [ItemContextMenuOption]()

            firstOptions.append(.init(title: "Copy alias address",
                                      icon: IconProvider.squares,
                                      action: onCopyAlias))

            if isEditable {
                if item.aliasEnabled {
                    firstOptions.append(.init(title: "Disable alias",
                                              icon: PassIcon.aliasSlash,
                                              action: { onToggleAliasStatus(false) }))
                } else {
                    firstOptions.append(.init(title: "Enable alias",
                                              icon: IconProvider.alias,
                                              action: { onToggleAliasStatus(true) }))
                }
            }
            var sections: [ItemContextMenuOptionSection] = []
            sections.append(.init(options: firstOptions))
            sections += Self.commonLastSections(item: item,
                                                isEditable: isEditable,
                                                canBeTrashed: canBeTrashed,
                                                onEdit: onEdit,
                                                onPinToggle: onPinToggle,
                                                onViewHistory: onViewHistory,
                                                onTrash: onTrash)

            return sections

        case let .creditCard(item,
                             isEditable,
                             canBeTrashed,
                             onCopyCardholderName,
                             onCopyCardNumber,
                             onCopyExpirationDate,
                             onCopySecurityCode,
                             onEdit,
                             onPinToggle,
                             onViewHistory,
                             onTrash):
            var sections: [ItemContextMenuOptionSection] = []

            sections.append(.init(options: [
                .init(title: "Copy cardholder name",
                      icon: IconProvider.user,
                      action: onCopyCardholderName),
                .init(title: "Copy card number",
                      icon: IconProvider.creditCard,
                      action: onCopyCardNumber),
                .init(title: "Copy expiration date",
                      icon: IconProvider.calendarDay,
                      action: onCopyExpirationDate),
                .init(title: "Copy security code",
                      icon: PassIcon.shieldCheck,
                      action: onCopySecurityCode)
            ]))

            sections += Self.commonLastSections(item: item,
                                                isEditable: isEditable,
                                                canBeTrashed: canBeTrashed,
                                                onEdit: onEdit,
                                                onPinToggle: onPinToggle,
                                                onViewHistory: onViewHistory,
                                                onTrash: onTrash)
            return sections

        case let .note(item,
                       isEditable,
                       canBeTrashed,
                       onCopyContent,
                       onEdit,
                       onPinToggle,
                       onViewHistory,
                       onTrash):
            var sections: [ItemContextMenuOptionSection] = []

            sections.append(.init(options: [.init(title: "Copy note content",
                                                  icon: IconProvider.note,
                                                  action: onCopyContent)]))

            sections += Self.commonLastSections(item: item,
                                                isEditable: isEditable,
                                                canBeTrashed: canBeTrashed,
                                                onEdit: onEdit,
                                                onPinToggle: onPinToggle,
                                                onViewHistory: onViewHistory,
                                                onTrash: onTrash)

            return sections

        case let .trashedItem(isEditable,
                              onRestore,
                              onPermanentlyDelete):
            if isEditable {
                return [
                    .init(options: [.init(title: "Restore",
                                          icon: IconProvider.clockRotateLeft,
                                          action: onRestore)]),
                    .init(options: [.init(title: "Delete permanently",
                                          icon: IconProvider.trashCross,
                                          action: onPermanentlyDelete,
                                          isDestructive: true)])
                ]
            } else {
                return []
            }

        case let .identity(item,
                           isEditable,
                           canBeTrashed,
                           onCopyEmail,
                           onCopyFullname,
                           onEdit,
                           onPinToggle,
                           onViewHistory,
                           onTrash):
            var sections: [ItemContextMenuOptionSection] = []

            sections.append(.init(options: [
                .init(title: "Copy email",
                      icon: IconProvider.envelope,
                      action: onCopyEmail),
                .init(title: "Copy full name",
                      icon: IconProvider.user,
                      action: onCopyFullname)
            ]))

            sections += Self.commonLastSections(item: item,
                                                isEditable: isEditable,
                                                canBeTrashed: canBeTrashed,
                                                onEdit: onEdit,
                                                onPinToggle: onPinToggle,
                                                onViewHistory: onViewHistory,
                                                onTrash: onTrash)

            return sections

        case let .sshKey(item,
                         isEditable,
                         canBeTrashed,
                         onEdit,
                         onPinToggle,
                         onViewHistory,
                         onTrash):
            return Self.commonLastSections(item: item,
                                           isEditable: isEditable,
                                           canBeTrashed: canBeTrashed,
                                           onEdit: onEdit,
                                           onPinToggle: onPinToggle,
                                           onViewHistory: onViewHistory,
                                           onTrash: onTrash)

        case let .wifi(item,
                       isEditable,
                       canBeTrashed,
                       onCopySsid,
                       onCopyPassword,
                       onEdit,
                       onPinToggle,
                       onViewHistory,
                       onTrash):
            var sections: [ItemContextMenuOptionSection] = []

            sections.append(.init(options: [
                .init(title: "Copy SSID",
                      icon: Image(systemName: "wifi"),
                      action: onCopySsid),
                .init(title: "Copy password",
                      icon: IconProvider.key,
                      action: onCopyPassword)
            ]))

            sections += Self.commonLastSections(item: item,
                                                isEditable: isEditable,
                                                canBeTrashed: canBeTrashed,
                                                onEdit: onEdit,
                                                onPinToggle: onPinToggle,
                                                onViewHistory: onViewHistory,
                                                onTrash: onTrash)

            return sections

        case let .custom(item,
                         isEditable,
                         canBeTrashed,
                         onEdit,
                         onPinToggle,
                         onViewHistory,
                         onTrash):
            return Self.commonLastSections(item: item,
                                           isEditable: isEditable,
                                           canBeTrashed: canBeTrashed,
                                           onEdit: onEdit,
                                           onPinToggle: onPinToggle,
                                           onViewHistory: onViewHistory,
                                           onTrash: onTrash)
        }
    }
}

private extension ItemContextMenu {
    static func commonLastSections(item: any PinnableItemTypeIdentifiable,
                                   isEditable: Bool,
                                   canBeTrashed: Bool,
                                   onEdit: @escaping () -> Void,
                                   onPinToggle: @escaping () -> Void,
                                   onViewHistory: @escaping () -> Void,
                                   onTrash: @escaping () -> Void) -> [ItemContextMenuOptionSection] {
        var sections: [ItemContextMenuOptionSection] = []

        if isEditable {
            sections.append(.init(options: [.editOption(action: onEdit)]))
        }

        sections.append(.init(options: [.pinToggleOption(item: item, action: onPinToggle)]))

        sections.append(.init(options: [.viewHistoryOption(action: onViewHistory)]))

        if isEditable, canBeTrashed {
            sections.append(.init(options: [.trashOption(action: onTrash)]))
        }

        return sections
    }
}

struct ItemContextMenuOption: Identifiable {
    var id = UUID()
    let title: LocalizedStringKey
    let icon: Image
    let action: () -> Void
    var isDestructive = false

    var buttonRole: ButtonRole? {
        isDestructive ? .destructive : nil
    }

    static func editOption(action: @escaping () -> Void) -> ItemContextMenuOption {
        .init(title: "Edit", icon: IconProvider.pencil, action: action)
    }

    static func pinToggleOption(item: any PinnableItemTypeIdentifiable,
                                action: @escaping () -> Void) -> ItemContextMenuOption {
        .init(title: item.pinTitle, icon: item.pinIcon, action: action)
    }

    static func viewHistoryOption(action: @escaping () -> Void) -> ItemContextMenuOption {
        .init(title: "View history", icon: IconProvider.clock, action: action)
    }

    static func trashOption(action: @escaping () -> Void) -> ItemContextMenuOption {
        .init(title: "Move to Trash",
              icon: IconProvider.trash,
              action: action,
              isDestructive: true)
    }
}

struct ItemContextMenuOptionSection: Identifiable {
    var id = UUID()
    let options: [ItemContextMenuOption]
}

private extension View {
    func itemContextMenu(_ menu: ItemContextMenu) -> some View {
        contextMenu {
            ForEach(menu.sections) { section in
                Section {
                    ForEach(section.options) { option in
                        Label(option.title, image: option.icon)
                            .buttonEmbeded(role: option.buttonRole, action: option.action)
                    }
                }
            }
        }
    }
}

struct PermenentlyDeleteItemModifier: ViewModifier {
    @Binding var item: (any ItemTypeIdentifiable)?
    let onDisableAlias: () -> Void
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(title,
                   isPresented: $item.mappedToBool(),
                   actions: {
                       if item?.aliasEmail == nil {
                           Button(role: .destructive, action: onDelete, label: { Text("Delete") })
                       } else {
                           if item?.aliasEnabled == true {
                               Button(action: onDisableAlias,
                                      label: { Text("Disable alias") })
                           }
                           Button(role: .destructive,
                                  action: onDelete,
                                  label: { Text("Delete it, I will never need it") })
                       }
                       Button(role: .cancel, label: { Text("Cancel") })
                   },
                   message: { Text(message) })
    }
}

private extension PermenentlyDeleteItemModifier {
    var title: LocalizedStringKey {
        if let aliasEmail = item?.aliasEmail {
            "Delete \(aliasEmail)"
        } else {
            "Delete permanently?"
        }
    }

    var message: LocalizedStringKey {
        if item?.shared == true {
            "This item is currently shared. Deleting it will remove access for all other users."
        } else if item?.aliasEmail == nil {
            "You are going to delete the item irreversibly, are you sure?"
        } else {
            item?.aliasEnabled == true ?
                "Please note once deleted, the alias can't be restored. Maybe you want to disable the alias instead?" :
                // swiftlint:disable:next line_length
                "Please note once deleted, the alias can't be restored. The alias is already disabled and won't forward emails to your mailbox."
        }
    }
}

extension View {
    @MainActor
    func itemContextMenu(item: any PinnableItemTypeIdentifiable,
                         isTrashed: Bool,
                         isEditable: Bool,
                         canBeTrashed: Bool,
                         onPermanentlyDelete: @escaping () -> Void,
                         onAliasTrash: @escaping () -> Void,
                         handler: ItemContextMenuHandler) -> some View {
        if isTrashed {
            itemContextMenu(.trashedItem(isEditable: isEditable,
                                         onRestore: { handler.restore(item) },
                                         onPermanentlyDelete: onPermanentlyDelete))
        } else {
            switch item.type {
            case .login:
                itemContextMenu(.login(item: item,
                                       isEditable: isEditable,
                                       canBeTrashed: canBeTrashed,
                                       onCopyEmail: { handler.copyEmail(item) },
                                       onCopyUsername: { handler.copyItemUsername(item) },
                                       onCopyPassword: { handler.copyPassword(item) },
                                       onEdit: { handler.edit(item) },
                                       onPinToggle: { handler.toggleItemPinning(item) },
                                       onViewHistory: { handler.viewHistory(item) },
                                       onTrash: { handler.trash(item) }))

            case .alias:
                itemContextMenu(.alias(item: item,
                                       isEditable: isEditable,
                                       canBeTrashed: canBeTrashed,
                                       onCopyAlias: { handler.copyAlias(item) },
                                       onToggleAliasStatus: { enabled in
                                           handler.toggleAliasStatus(item, enabled: enabled)
                                       },
                                       onEdit: { handler.edit(item) },
                                       onPinToggle: { handler.toggleItemPinning(item) },
                                       onViewHistory: { handler.viewHistory(item) },
                                       onTrash: onAliasTrash))

            case .creditCard:
                itemContextMenu(.creditCard(item: item,
                                            isEditable: isEditable,
                                            canBeTrashed: canBeTrashed,
                                            onCopyCardholderName: { handler.copyCardholderName(item) },
                                            onCopyCardNumber: { handler.copyCardNumber(item) },
                                            onCopyExpirationDate: { handler.copyExpirationDate(item) },
                                            onCopySecurityCode: { handler.copySecurityCode(item) },
                                            onEdit: { handler.edit(item) },
                                            onPinToggle: { handler.toggleItemPinning(item) },
                                            onViewHistory: { handler.viewHistory(item) },
                                            onTrash: { handler.trash(item) }))

            case .note:
                itemContextMenu(.note(item: item,
                                      isEditable: isEditable,
                                      canBeTrashed: canBeTrashed,
                                      onCopyContent: { handler.copyNoteContent(item) },
                                      onEdit: { handler.edit(item) },
                                      onPinToggle: { handler.toggleItemPinning(item) },
                                      onViewHistory: { handler.viewHistory(item) },
                                      onTrash: { handler.trash(item) }))

            case .identity:
                itemContextMenu(.identity(item: item,
                                          isEditable: isEditable,
                                          canBeTrashed: canBeTrashed,
                                          onCopyEmail: { handler.copyEmail(item) },
                                          onCopyFullname: { handler.copyFullname(item) },
                                          onEdit: { handler.edit(item) },
                                          onPinToggle: { handler.toggleItemPinning(item) },
                                          onViewHistory: { handler.viewHistory(item) },
                                          onTrash: { handler.trash(item) }))

            case .sshKey:
                itemContextMenu(.sshKey(item: item,
                                        isEditable: isEditable,
                                        canBeTrashed: canBeTrashed,
                                        onEdit: { handler.edit(item) },
                                        onPinToggle: { handler.toggleItemPinning(item) },
                                        onViewHistory: { handler.viewHistory(item) },
                                        onTrash: { handler.trash(item) }))

            case .wifi:
                itemContextMenu(.wifi(item: item,
                                      isEditable: isEditable,
                                      canBeTrashed: canBeTrashed,
                                      onCopySsid: { handler.copySsid(item) },
                                      onCopyPassword: { handler.copyWifiPassword(item) },
                                      onEdit: { handler.edit(item) },
                                      onPinToggle: { handler.toggleItemPinning(item) },
                                      onViewHistory: { handler.viewHistory(item) },
                                      onTrash: { handler.trash(item) }))

            case .custom:
                itemContextMenu(.custom(item: item,
                                        isEditable: isEditable,
                                        canBeTrashed: canBeTrashed,
                                        onEdit: { handler.edit(item) },
                                        onPinToggle: { handler.toggleItemPinning(item) },
                                        onViewHistory: { handler.viewHistory(item) },
                                        onTrash: { handler.trash(item) }))
            }
        }
    }
}

// swiftlint:enable enum_case_associated_values_count function_parameter_count
