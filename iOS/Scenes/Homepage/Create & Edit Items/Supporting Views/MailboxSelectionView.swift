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
import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct MailboxSelectionView: View {
    private let theme = resolve(\SharedToolingContainer.theme)
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MailboxSelectionViewModel

    init(viewModel: MailboxSelectionViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    private var selection: MailboxSelection { viewModel.mailboxSelection }

    var body: some View {
        NavigationView {
            // ZStack instead of VStack because of SwiftUI bug.
            // See more in "CreateAliasLiteView.swift"
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(selection.mailboxes, id: \.ID) { mailbox in
                            HStack {
                                Text(mailbox.email)
                                    .foregroundColor(isSelected(mailbox) ?
                                        viewModel.mode.tintColor : Color(uiColor: PassColor.textNorm))
                                Spacer()

                                if isSelected(mailbox) {
                                    Image(uiImage: IconProvider.checkmark)
                                        .foregroundColor(viewModel.mode.tintColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .background(Color.clear)
                            .padding(.horizontal)
                            .frame(height: OptionRowHeight.compact.value)
                            .onTapGesture {
                                selection.selectedMailboxes.insertOrRemove(mailbox, minItemCount: 1)
                            }

                            PassDivider()
                                .padding(.horizontal)
                        }

                        if viewModel.shouldUpgrade {
                            upgradeButton
                            PassDivider()
                                .padding(.horizontal)
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
            .background(Color(uiColor: PassColor.backgroundWeak))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(viewModel.titleMode.title)
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
        .theme(theme)
    }

    private func isSelected(_ mailbox: Mailbox) -> Bool {
        selection.selectedMailboxes.contains(mailbox)
    }

    private var upgradeButton: some View {
        Button(action: viewModel.upgrade) {
            HStack {
                Text("Upgrade for more mailboxes")
                Image(uiImage: IconProvider.arrowOutSquare)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 20)
            }
            .contentShape(Rectangle())
            .foregroundColor(viewModel.mode.tintColor)
        }
        .frame(height: OptionRowHeight.compact.value)
    }

    private var closeButton: some View {
        Button(action: dismiss.callAsFunction) {
            Text("Close")
                .foregroundColor(Color(uiColor: PassColor.textNorm))
        }
    }
}
