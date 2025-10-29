//
// MailboxSelectionView.swift
// Proton Pass - Created on 01/08/2024.
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct MailboxSelectionView: View {
    @Binding var mailboxSelection: AliasLinkedMailboxSelection
    let title: String
    var tint = PassColor.aliasInteractionNormMajor2
    let showTip: Bool
    let onAddMailbox: () -> Void
    let onDismissTip: () -> Void

    var body: some View {
        NavigationStack {
            // ZStack instead of VStack because of SwiftUI bug.
            // See more in "CreateAliasLiteView.swift"
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(mailboxSelection.allUserMailboxes) { mailbox in
                            let isSelected = mailboxSelection.selectedMailboxes.contains(mailbox)
                            HStack {
                                Text(mailbox.email)
                                    .foregroundStyle(isSelected ? tint : PassColor.textNorm)
                                Spacer()

                                if isSelected {
                                    IconProvider.checkmark
                                        .foregroundStyle(tint)
                                }
                            }
                            .contentShape(.rect)
                            .background(Color.clear)
                            .padding(.horizontal)
                            .frame(height: OptionRowHeight.compact.value)
                            .onTapGesture {
                                mailboxSelection.selectedMailboxes.insertOrRemove(mailbox, minItemCount: 1)
                            }

                            if mailbox != mailboxSelection.allUserMailboxes.last {
                                PassDivider()
                                    .padding(.horizontal)
                            }
                        }

                        if showTip {
                            tip
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(PassColor.backgroundWeak)
            .animation(.default, value: showTip)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .navigationTitleText()
                }
            }
        }
    }
}

private extension MailboxSelectionView {
    var tip: some View {
        TipBanner(configuration: .init(arrowMode: .none,
                                       description: tipDescription,
                                       cta: .init(title: #localized("Add mailbox", bundle: .module),
                                                  action: onAddMailbox)),
                  onDismiss: onDismissTip)
    }

    var tipDescription: LocalizedStringKey {
        "Share aliases with others by adding their inbox as an additional mailbox."
    }
}
