//
// MailboxSelectionView.swift
// Proton Pass - Created on 17/02/2023.
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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct MailboxSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var mailboxSelection: MailboxSelection
    let mode: Mode
    let titleMode: MailboxSection.Mode

    enum Mode {
        case createEditAlias
        case createAliasLite

        var tintColor: Color {
            switch self {
            case .createEditAlias:
                return Color(uiColor: ItemContentType.alias.normMajor2Color)
            case .createAliasLite:
                return Color(uiColor: ItemContentType.login.normMajor2Color)
            }
        }
    }

    var body: some View {
        NavigationView {
            // ZStack instead of VStack because of SwiftUI bug.
            // See more in "CreateAliasLiteView.swift"
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack {
                        ForEach(mailboxSelection.mailboxes, id: \.ID) { mailbox in
                            HStack {
                                Text(mailbox.email)
                                    .foregroundColor(isSelected(mailbox) ?
                                                     mode.tintColor : Color(uiColor: PassColor.textNorm))
                                Spacer()

                                if isSelected(mailbox) {
                                    Image(uiImage: IconProvider.checkmark)
                                        .foregroundColor(mode.tintColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .background(Color.clear)
                            .padding(.horizontal)
                            .frame(height: 32)
                            .onTapGesture {
                                mailboxSelection.selectedMailboxes.insertOrRemove(mailbox, minItemCount: 1)
                            }

                            PassDivider()
                                .padding(.horizontal)
                        }

                        closeButton
                            .opacity(0)
                            .disabled(true)
                    }
                }

                closeButton
                    .padding()
            }
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NavigationTitleWithHandle(title: titleMode.title)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func isSelected(_ mailbox: Mailbox) -> Bool {
        mailboxSelection.selectedMailboxes.contains(mailbox)
    }

    private var closeButton: some View {
        Button(action: dismiss.callAsFunction) {
            Text("Close")
                .foregroundColor(Color(uiColor: PassColor.textNorm))
        }
    }
}