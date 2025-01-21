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
}

public struct AliasOptionsSheetContent: View {
    @StateObject private var viewModel: AliasOptionsSheetContentViewModel
    private let onDismiss: () -> Void

    public init(state: AliasOptionsSheetState,
                onDismiss: @escaping () -> Void) {
        _viewModel = .init(wrappedValue: .init(state: state))
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case let .mailbox(mailboxSelection, title):
                MailboxSelectionView(mailboxSelection: mailboxSelection,
                                     title: title,
                                     showTip: viewModel.showMailboxTip,
                                     onAddMailbox: viewModel.addMailbox,
                                     onDismissTip: viewModel.dismissMailboxTip)
            case let .suffix(suffixSelection):
                SuffixSelectionView(selection: suffixSelection,
                                    showTip: viewModel.showDomainTip,
                                    onAddDomain: viewModel.addDomain,
                                    onDismissTip: viewModel.dismissDomainTip,
                                    onDismiss: onDismiss)
            }
        }
        .presentationDetents([.height(viewModel.height)])
        .presentationDragIndicator(.visible)
    }
}

@MainActor
private final class AliasOptionsSheetContentViewModel: ObservableObject {
    @Published private(set) var showMailboxTip = true
    @Published private(set) var showDomainTip = true
    let state: AliasOptionsSheetState

    var height: CGFloat {
        let elementCount = switch state {
        case let .mailbox(selection, _):
            selection.wrappedValue.allUserMailboxes.count
        case let .suffix(selection):
            selection.wrappedValue.suffixes.count
        }

        let showTip = switch state {
        case .mailbox:
            showMailboxTip
        case .suffix:
            showDomainTip
        }

        let tipHeight: CGFloat = showTip ? 120 : 0

        return OptionRowHeight.compact.value * CGFloat(elementCount) + tipHeight + 60 // nav bar
    }

    init(state: AliasOptionsSheetState) {
        self.state = state
    }

    func addMailbox() {
        print(#function)
    }

    func dismissMailboxTip() {
        showMailboxTip = false
    }

    func addDomain() {
        print(#function)
    }

    func dismissDomainTip() {
        showDomainTip = false
    }
}
