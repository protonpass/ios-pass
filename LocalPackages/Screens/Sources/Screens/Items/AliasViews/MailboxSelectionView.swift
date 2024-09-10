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
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct MailboxSelectionView: View {
    @Binding var mailboxSelection: AliasLinkedMailboxSelection
    let title: String
    var tint = PassColor.aliasInteractionNormMajor2.toColor
    let onDismiss: () -> Void

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
                                    .foregroundStyle(isSelected ? tint : PassColor.textNorm.toColor)
                                Spacer()

                                if isSelected {
                                    Image(uiImage: IconProvider.checkmark)
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

                        // Gimmick view to take up space
                        closeButton
                            .opacity(0)
                            .padding()
                            .disabled(true)
                    }
                }

                closeButton
                    .padding()
            }
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .navigationTitleText()
                }
            }
        }
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Text("Close")
                .foregroundStyle(PassColor.textNorm.toColor)
        }
    }
}
