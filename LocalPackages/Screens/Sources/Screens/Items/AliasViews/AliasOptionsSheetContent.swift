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
import Entities
import Foundation
import SwiftUI

public enum AliasOptionsSheetState {
    case mailbox(Binding<AliasLinkedMailboxSelection>, String)
    case suffix(Binding<SuffixSelection>)
}

public struct AliasOptionsSheetContent: View {
    @StateObject private var viewModel: AliasOptionsSheetContentViewModel
    private let aliasDiscoveryActive: Bool
    private let onAddMailbox: () -> Void
    private let onAddDomain: () -> Void
    private let onDismiss: () -> Void

    public init(module: PassModule,
                preferencesManager: any PreferencesManagerProtocol,
                state: AliasOptionsSheetState,
                aliasDiscoveryActive: Bool,
                aliasCount: Int?,
                onAddMailbox: @escaping () -> Void,
                onAddDomain: @escaping () -> Void,
                onDismiss: @escaping () -> Void,
                onError: @escaping (any Error) -> Void) {
        _viewModel = .init(wrappedValue: .init(module: module,
                                               preferencesManager: preferencesManager,
                                               state: state,
                                               aliasCount: aliasCount,
                                               onError: onError))
        self.aliasDiscoveryActive = aliasDiscoveryActive
        self.onAddMailbox = onAddMailbox
        self.onAddDomain = onAddDomain
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case let .mailbox(mailboxSelection, title):
                MailboxSelectionView(mailboxSelection: mailboxSelection,
                                     title: title,
                                     showTip: aliasDiscoveryActive && viewModel.showMailboxTip,
                                     onAddMailbox: {
                                         viewModel.dismissMailboxTip(completion: onAddMailbox)
                                     },
                                     onDismissTip: { viewModel.dismissMailboxTip() })
            case let .suffix(suffixSelection):
                SuffixSelectionView(selection: suffixSelection,
                                    showTip: aliasDiscoveryActive && viewModel.showDomainTip,
                                    onAddDomain: {
                                        viewModel.dismissDomainTip(completion: onAddDomain)
                                    },
                                    onDismissTip: { viewModel.dismissDomainTip() },
                                    onDismiss: onDismiss)
            }
        }
        .presentationDetents([.height(viewModel.height)])
        .presentationDragIndicator(.visible)
    }
}

@MainActor
private final class AliasOptionsSheetContentViewModel: ObservableObject {
    @Published private(set) var showMailboxTip = false
    @Published private(set) var showDomainTip = false
    private let aliasCount: Int?
    private let preferencesManager: any PreferencesManagerProtocol
    private let onError: (any Error) -> Void
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
         preferencesManager: any PreferencesManagerProtocol,
         state: AliasOptionsSheetState,
         aliasCount: Int?,
         onError: @escaping (any Error) -> Void) {
        self.state = state
        self.preferencesManager = preferencesManager
        self.aliasCount = aliasCount
        self.onError = onError

        if module == .hostApp {
            switch state {
            case let .mailbox(selection, _):
                if let aliasCount,
                   aliasCount > 2,
                   selection.wrappedValue.allUserMailboxes.count <= 1 {
                    showMailboxTip = !aliasDiscovery.contains(.mailboxes)
                }

            case let .suffix(selection):
                if selection.wrappedValue.suffixes.count(where: { $0.isCustom }) == 0 {
                    showDomainTip = !aliasDiscovery.contains(.customDomains)
                }
            }
        }
    }

    func dismissMailboxTip(completion: (() -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            var aliasDiscovery = aliasDiscovery
            guard !aliasDiscovery.contains(.mailboxes) else { return }
            do {
                aliasDiscovery.flip(.mailboxes)
                try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                     value: aliasDiscovery)
                showMailboxTip = false
                completion?()
            } catch {
                onError(error)
            }
        }
    }

    func dismissDomainTip(completion: (() -> Void)? = nil) {
        Task { [weak self] in
            guard let self else { return }
            var aliasDiscovery = aliasDiscovery
            guard !aliasDiscovery.contains(.customDomains) else { return }
            do {
                aliasDiscovery.flip(.customDomains)
                try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                     value: aliasDiscovery)
                showDomainTip = false
                completion?()
            } catch {
                onError(error)
            }
        }
    }
}
