//
// View+Extension.swift
// Proton Pass - Created on 02/08/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import Foundation
import SwiftUI

public enum AliasOptionsSheetState {
    case mailbox(Binding<AliasLinkedMailboxSelection>, String)
    case suffix(Binding<SuffixSelection>)

    public var height: CGFloat {
        switch self {
        case let .mailbox(mailboxSelection, _):
            OptionRowHeight.compact.value * CGFloat(mailboxSelection.wrappedValue.allUserMailboxes.count) + 150
        case .suffix:
            280
        }
    }
}

public extension View {
    @ViewBuilder
    func aliasOptionsSheetContent(for state: AliasOptionsSheetState) -> some View {
        switch state {
        case let .mailbox(mailboxSelection, title):
            MailboxSelectionView(mailboxSelection: mailboxSelection,
                                 title: title)
        case let .suffix(suffixSelection):
            SuffixSelectionView(selection: suffixSelection)
        }
    }
}
