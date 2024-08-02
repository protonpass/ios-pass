//
// MailboxSelectionViewModel.swift
// Proton Pass - Created on 03/05/2023.
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

import Combine
import Core
import Entities
import Factory
import SwiftUI

// @MainActor
// final class MailboxSelectionViewModel: ObservableObject, DeinitPrintable {
//    deinit { print(deinitMessage) }
//
//    @Published private(set) var shouldUpgrade = false
////    @Binding private var selectedMailboxes: [Mailbox]
//
//    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
//    let allMailBoxes: [Mailbox]
//    let mode: Mode
//    let title: String
//
//    private var cancellables = Set<AnyCancellable>()
//
//    enum Mode {
//        case createEditAlias
//        case createAliasLite
//
//        var tintColor: Color {
//            switch self {
//            case .createEditAlias:
//                ItemContentType.alias.normMajor2Color.toColor
//            case .createAliasLite:
//                ItemContentType.login.normMajor2Color.toColor
//            }
//        }
//    }
//
//    init(allMailBoxes: [Mailbox],
////         selectedMailboxes: Binding<[Mailbox]>,
//         mode: MailboxSelectionViewModel.Mode,
//         title: String) {
//        self.allMailBoxes = allMailBoxes
//        self.mode = mode
//        self.title = title
////        _selectedMailboxes = selectedMailboxes
////
////        mailboxSelection.attach(to: self, storeIn: &cancellables)
//    }
//
////    func isMailboxSelected(_ mailbox: Mailbox) -> Bool {
//    ////        print("woot: *************")
//    ////        print("woot mailbox \(mailbox)")
//    ////        print("woot selectedMailboxes \(selectedMailboxes)")
//    ////        print("woot: \n ************* \n")
////
//    ////        return selectedMailboxes.contains(mailbox)
////    }
//
//    func insertOrRemove(mailbox: Mailbox) {
////        selectedMailboxes.insertOrRemove(mailbox, minItemCount: 1)
////        selectedMailboxes = []
////        selectedMailboxes.objectWillChange.send()
//    }
//
//    func upgrade() {
//        router.present(for: .upgradeFlow)
//    }
// }

// public extension Array where Element: Equatable {
//    /// Insert if not exist, remove if exist. This method is designed for arrays with unique elements only.
//    /// So be careful when using on an array of repeated elements, it will result in undefined behaviors.
//    /// - Parameters:
//    ///  - element: New element to insert or remove.
//    ///  - minItemCount: Minimum number of item that the array must have after removing an element.
//    ///  Use to make sure array always  has at least a certain number of items.
//    mutating func insertOrRemove(_ element: Element, minItemCount: UInt = 0) {
//        if contains(element) {
//            if count - 1 >= minItemCount {
//                removeAll { $0 == element }
//            }
//        } else {
//            append(element)
//        }
//    }
// }
