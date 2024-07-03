//
// AccountList.swift
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
import ProtonCoreUIFoundations
import SwiftUI

struct AccountList: View {
    @State private var animated = false
    @State private var accountToManage: AccountCellDetail?
    @State private var accountToSignOut: AccountCellDetail?

    let details: [AccountCellDetail]
    let activeId: String
    let animationNamespace: Namespace.ID
    let onSelect: (AccountCellDetail) -> Void
    let onManage: (AccountCellDetail) -> Void
    let onSignOut: (AccountCellDetail) -> Void
    let onAddAccount: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 2) {
            ForEach(details, id: \.id) { detail in
                let isActive = detail.id == activeId
                if isActive || (!isActive && animated) {
                    row(for: detail, isActive: isActive)

                    if isActive, details.count > 1 {
                        Text("Switch to")
                            .font(.callout.bold())
                            .foregroundStyle(PassColor.textNorm.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, DesignConstant.sectionPadding)
                    }

                    if !isActive {
                        PassDivider()
                            .padding(.vertical, DesignConstant.sectionPadding / 2)
                    }
                }
            }

            if animated {
                if details.count == 1 {
                    PassDivider()
                        .padding(.vertical, DesignConstant.sectionPadding / 2)
                }
                addAcountRow
            }
        }
        .padding(DesignConstant.sectionPadding)
        .background(PassColor.backgroundNorm.toColor)
        .roundedEditableSection()
        .animation(.default, value: animated)
        .onFirstAppear {
            animated.toggle()
        }
        .alert(Text("Manage account"),
               isPresented: $accountToManage.mappedToBool(),
               presenting: accountToManage,
               actions: { account in
                   Button(action: { onManage(account) },
                          label: { Text("Yes, switch account") })
                   Button(role: .cancel, label: { Text("Cancel") })
               },
               message: { account in
                   Text("You need to switch to \(account.email) in order to manage it")
               })
        .alert(Text("Sign out"),
               isPresented: $accountToSignOut.mappedToBool(),
               presenting: accountToSignOut,
               actions: { account in
                   Button(role: .destructive,
                          action: { onSignOut(account) },
                          label: { Text("Yes, sign out") })
                   Button(role: .cancel, label: { Text("Cancel") })
               },
               message: { account in
                   Text("Sign out from \(account.email)?")
               })
    }
}

private extension AccountList {
    func row(for detail: AccountCellDetail, isActive: Bool) -> some View {
        HStack {
            AccountCell(detail: detail,
                        isActive: isActive,
                        showInactiveIcon: isActive,
                        animationNamespace: animationNamespace)
                .onTapGesture {
                    onSelect(detail)
                }

            Menu(content: {
                Button(action: { handleManage(detail) },
                       label: { Label(title: { Text("Manage account") },
                                      icon: { Image(uiImage: IconProvider.cogWheel) }) })

                Divider()

                Button(action: { accountToSignOut = detail },
                       label: { Label(title: { Text("Sign out") },
                                      icon: { Image(uiImage: IconProvider.arrowOutFromRectangle) }) })
            }, label: {
                icon(with: IconProvider.threeDotsVertical,
                     foregroundColor: PassColor.textWeak)
            })
        }
    }

    var addAcountRow: some View {
        HStack {
            icon(with: IconProvider.userPlus,
                 foregroundColor: PassColor.textNorm)
            Text("Add account")
                .foregroundStyle(PassColor.textNorm.toColor)
            Spacer()
        }
        .contentShape(.rect)
        .onTapGesture(perform: onAddAccount)
    }

    func icon(with uiImage: UIImage, foregroundColor: UIColor) -> some View {
        SwiftUIImage(image: uiImage, width: 24, tintColor: foregroundColor)
    }
}

private extension AccountList {
    func handleManage(_ account: AccountCellDetail) {
        if account.id == activeId {
            onManage(account)
        } else {
            accountToManage = account
        }
    }
}
