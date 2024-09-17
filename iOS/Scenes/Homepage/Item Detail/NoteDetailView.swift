//
// NoteDetailView.swift
// Proton Pass - Created on 07/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

struct NoteDetailView: View {
    @StateObject private var viewModel: NoteDetailViewModel
    @Namespace private var bottomID

    init(viewModel: NoteDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if viewModel.isShownAsSheet {
            NavigationStack {
                realBody
            }
        } else {
            realBody
        }
    }

    @ViewBuilder
    private var realBody: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    let itemContent = viewModel.itemContent

                    HStack(alignment: .firstTextBaseline) {
                        if itemContent.item.pinned {
                            PinCircleView(tintColor: itemContent.contentData.type.normMajor1Color,
                                          height: 24)
                        }

                        TextView(.constant(viewModel.name))
                            .font(.title)
                            .fontWeight(.bold)
                            .isEditable(false)
                            // swiftlint:disable:next deprecated_foregroundcolor_modifier
                            .foregroundColor(PassColor.textNorm)
                    }
                    .animation(.default, value: itemContent.item.pinned)

                    HStack {
                        if let vault = viewModel.vault?.vault {
                            if !vault.shared {
                                VaultLabel(vault: vault)
                                    .padding(.top, 4)
                            } else {
                                VaultButton(vault: vault)
                                    .padding(.top, 4)
                            }
                        }
                        Spacer()
                    }

                    Spacer(minLength: 16)

                    if viewModel.note.isEmpty {
                        Text("Empty note")
                            .placeholderText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        TextView(.constant(viewModel.note))
                            .autoDetectDataTypes(.all)
                            .isEditable(false)
                    }

                    ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                             action: { viewModel.showItemHistory() })

                    ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                              itemContent: viewModel.itemContent,
                                              vault: viewModel.vault?.vault,
                                              onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
                        .padding(.top, 24)
                        .id(bottomID)
                }
                .padding()
            }
            .animation(.default, value: viewModel.moreInfoSectionExpanded)
            .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
            }
        }
        .itemDetailSetUp(viewModel)
    }
}
