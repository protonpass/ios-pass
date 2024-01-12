//
//
// DetailHistoryView.swift
// Proton Pass - Created on 11/01/2024.
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
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct DetailHistoryView: View {
    @StateObject var viewModel: DetailHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false

    var body: some View {
        mainContainer
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DesignConstant.sectionPadding)
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundNorm.toColor)
            .toolbar { toolbarContent }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Restore this version?"),
                      message: Text(#localized("Your current document will revert to the version from %@",
                                               viewModel.revision.revisionDate)),
                      primaryButton: .default(Text("Restore"),
                                              action: { viewModel.restore() }),
                      secondaryButton: .cancel())
            }
            .showSpinner(viewModel.restoringItem)
    }
}

private extension DetailHistoryView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.arrowLeft,
                         iconColor: viewModel.selectedItem.contentData.type.normMajor2Color,
                         backgroundColor: viewModel.selectedItem.contentData.type.normMinor1Color,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CapsuleLabelButton(icon: IconProvider.clockRotateLeft,
                               title: #localized("Restore"),
                               titleColor: viewModel.selectedItem.contentData.type.normMajor2Color,
                               backgroundColor: viewModel.selectedItem.contentData.type.normMinor1Color,
                               action: { showAlert = true })
        }
    }
}

private extension DetailHistoryView {
    var mainContainer: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { _ in
                ScrollView {
                    if viewModel.selectedItem.contentData == .note {
                        noteView
                    } else {
                        Text(verbatim: "This is a temporary empty state")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(PassColor.backgroundNorm.toColor)
                    }
                }
                .animation(.default, value: viewModel.selectedItem)
            }
            .padding(.bottom, 50)

            SegmentedPicker(selectedIndex: $viewModel.selectedItemIndex,
                            options: [viewModel.revision.shortRevisionDate, #localized("Current")],
                            textColor: PassColor.textInvert.toColor,
                            mainColor: viewModel.selectedItem.contentData.type.normMajor2Color.toColor,
                            backgroundColor: viewModel.selectedItem.contentData.type.normMinor1Color.toColor)
        }
    }
}

private extension DetailHistoryView {
    var noteView: some View {
        VStack(alignment: .leading, spacing: 0) {
            let itemContent = viewModel.selectedItem

            HStack(alignment: .firstTextBaseline) {
                Text(itemContent.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .padding(DesignConstant.sectionPadding)
                    .roundedDetailSection(color: viewModel.isDifferent(for: .name) ? PassColor.signalWarning
                        .toColor : PassColor.inputBorderNorm
                        .toColor)
                Spacer()
            }

            Spacer(minLength: 16)

            Group {
                if itemContent.note.isEmpty {
                    Text("Empty note")
                        .placeholderText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(itemContent.note)
                }
            }
            .padding(DesignConstant.sectionPadding)
            .roundedDetailSection(color: viewModel.isDifferent(for: .note) ? PassColor.signalWarning
                .toColor : PassColor.inputBorderNorm
                .toColor)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
