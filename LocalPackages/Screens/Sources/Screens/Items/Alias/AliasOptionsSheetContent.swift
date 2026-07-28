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

import Client
import DesignSystem
import DIComposition
import Entities
import FactoryKit
import Foundation
import SwiftUI

public enum AliasOptionsSheetState {
    case mailbox(Binding<AliasLinkedMailboxSelection>, String)
    case suffix(Binding<SuffixSelection>)
}

public enum AliasOptionsSheetContentAction {
    case addMailbox
    case addDomain
    case shouldDismiss
    case hasError(any Error)
}

public struct AliasOptionsSheetContent: View {
    @State private var viewModel: AliasOptionsSheetContentViewModel
    private let action: (AliasOptionsSheetContentAction) -> Void

    public init(module: PassModule,
                state: AliasOptionsSheetState,
                aliasCount: Int?,
                action: @escaping (AliasOptionsSheetContentAction) -> Void) {
        _viewModel = .init(wrappedValue: .init(module: module,
                                               state: state,
                                               aliasCount: aliasCount,
                                               action: action))
        self.action = action
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case let .mailbox(mailboxSelection, title):
                MailboxSelectionView(mailboxSelection: mailboxSelection,
                                     title: title,
                                     showTip: viewModel.showMailboxTip,
                                     onAddMailbox: {
                                         viewModel.dismissMailboxTip(addMailBox: true)
                                     },
                                     onDismissTip: { viewModel.dismissMailboxTip() })

            case let .suffix(suffixSelection):
                SuffixSelectionView(selection: suffixSelection,
                                    showTip: viewModel.showDomainTip,
                                    onAddDomain: {
                                        viewModel.dismissDomainTip(addDomain: true)
                                    },
                                    onDismissTip: { viewModel.dismissDomainTip() },
                                    onDismiss: { action(.shouldDismiss) })
            }
        }
        .presentationDetents([.height(viewModel.height)])
        .presentationDragIndicator(.visible)
    }
}

@MainActor
@Observable
private final class AliasOptionsSheetContentViewModel {
    private(set) var showMailboxTip = false
    private(set) var showDomainTip = false

    private let aliasCount: Int?
    private let preferencesManager = dependency(\ToolingContainer.preferencesManager)
    private let action: (AliasOptionsSheetContentAction) -> Void

    let state: AliasOptionsSheetState

    private var aliasDiscovery: AliasDiscovery {
        preferencesManager.sharedPreferences.unwrapped().aliasDiscovery
    }

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

        let tipHeight: CGFloat = showTip ? 140 : 0

        return OptionRowHeight.compact.value * CGFloat(elementCount) + tipHeight + 60 // nav bar
    }

    init(module: PassModule,
         state: AliasOptionsSheetState,
         aliasCount: Int?,
         action: @escaping (AliasOptionsSheetContentAction) -> Void) {
        self.state = state
        self.aliasCount = aliasCount
        self.action = action

        if let aliasCount, aliasCount > 2, module == .hostApp {
            switch state {
            case let .mailbox(selection, _):
                if selection.wrappedValue.allUserMailboxes.count <= 1 {
                    showMailboxTip = !aliasDiscovery.contains(.mailboxes)
                }

            case let .suffix(selection):
                if selection.wrappedValue.suffixes.count(where: { $0.isCustom }) == 0 {
                    showDomainTip = !aliasDiscovery.contains(.customDomains)
                }
            }
        }
    }

    func dismissMailboxTip(addMailBox: Bool = false) {
        Task { [weak self] in
            guard let self else { return }
            var aliasDiscovery = aliasDiscovery
            guard !aliasDiscovery.contains(.mailboxes) else { return }
            do {
                aliasDiscovery.flip(.mailboxes)
                try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                     value: aliasDiscovery)
                showMailboxTip = false
                if addMailBox {
                    action(.addMailbox)
                }
            } catch {
                action(.hasError(error))
            }
        }
    }

    func dismissDomainTip(addDomain: Bool = false) {
        Task { [weak self] in
            guard let self else { return }
            var aliasDiscovery = aliasDiscovery
            guard !aliasDiscovery.contains(.customDomains) else { return }
            do {
                aliasDiscovery.flip(.customDomains)
                try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                     value: aliasDiscovery)
                showDomainTip = false
                if addDomain {
                    action(.addDomain)
                }
            } catch {
                action(.hasError(error))
            }
        }
    }
}
