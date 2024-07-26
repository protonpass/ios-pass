//
// AccountSwitchModifier.swift
// Proton Pass - Created on 26/06/2024.
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
//

import DesignSystem
import SwiftUI

public struct AccountSwitchModifier: ViewModifier {
    let details: [AccountCellDetail]
    let activeId: String
    @Binding var showSwitcher: Bool
    let animationNamespace: Namespace.ID
    let onSelect: (AccountCellDetail) -> Void
    let onManage: (AccountCellDetail) -> Void
    let onSignOut: (AccountCellDetail) -> Void
    let onAddAccount: () -> Void

    public init(details: [AccountCellDetail],
                activeId: String,
                showSwitcher: Binding<Bool>,
                animationNamespace: Namespace.ID,
                onSelect: @escaping (AccountCellDetail) -> Void,
                onManage: @escaping (AccountCellDetail) -> Void,
                onSignOut: @escaping (AccountCellDetail) -> Void,
                onAddAccount: @escaping () -> Void) {
        self.details = details
        self.activeId = activeId
        _showSwitcher = showSwitcher
        self.animationNamespace = animationNamespace
        self.onSelect = onSelect
        self.onManage = onManage
        self.onSignOut = onSignOut
        self.onAddAccount = onAddAccount
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                overlayContent
            }
            .animation(.default, value: showSwitcher)
    }

    @ViewBuilder
    var overlayContent: some View {
        if showSwitcher {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showSwitcher.toggle()
                        }
                    }

                VStack {
                    AccountList(details: details,
                                activeId: activeId,
                                animationNamespace: animationNamespace,
                                onSelect: { account in toggleSwitcher(onSelect(account)) },
                                onManage: { account in toggleSwitcher(onManage(account)) },
                                onSignOut: { account in toggleSwitcher(onSignOut(account)) },
                                onAddAccount: { toggleSwitcher(onAddAccount()) })
                    Spacer()
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension AccountSwitchModifier {
    func toggleSwitcher(_ completion: @autoclosure @escaping () -> Void) {
        if #available(iOS 17.0, *) {
            withAnimation {
                showSwitcher.toggle()
            } completion: {
                completion()
            }
        } else {
            let duration = DesignConstant.animationDuration
            withAnimation(.linear(duration: duration)) {
                showSwitcher.toggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completion()
            }
        }
    }
}
