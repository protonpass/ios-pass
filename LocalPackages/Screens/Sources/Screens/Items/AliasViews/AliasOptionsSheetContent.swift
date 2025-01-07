//
// AliasOptionsSheetContent.swift
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

    var height: CGFloat {
        let elementCount = switch self {
        case let .mailbox(selection, _):
            selection.wrappedValue.allUserMailboxes.count
        case let .suffix(selection):
            selection.wrappedValue.suffixes.count
        }

        return switch self {
        case .mailbox:
            OptionRowHeight.compact.value * CGFloat(elementCount) + 60 // nav bar
        case .suffix:
            OptionRowHeight.compact.value * CGFloat(elementCount) + 60 // nav bar
        }
    }
}

public struct AliasOptionsSheetContent: View {
    private let state: AliasOptionsSheetState
    private let onDismiss: () -> Void

    public init(state: AliasOptionsSheetState,
                onDismiss: @escaping () -> Void) {
        self.state = state
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Group {
            switch state {
            case let .mailbox(mailboxSelection, title):
                MailboxSelectionView(mailboxSelection: mailboxSelection,
                                     title: title,
                                     onDismiss: onDismiss)
            case let .suffix(suffixSelection):
                SuffixSelectionView(selection: suffixSelection, onDismiss: onDismiss)
            }
        }
        .presentationDetents([.height(state.height)])
        .presentationDragIndicator(.visible)
    }
}
