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
import Screens
import SwiftUI

struct DetailHistoryView: View {
    @StateObject var viewModel: DetailHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAlert = false
    @State var isShowingPassword = false
    @State var isShowingCardNumber = false
    @State var isShowingVerificationNumber = false
    @State var isShowingPIN = false

    var body: some View {
        mainContainer
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DesignConstant.sectionPadding)
            .navigationBarTitleDisplayMode(.inline)
            .tint(viewModel.currentRevision.type.normMajor2Color.toColor)
            .background(PassColor.backgroundNorm.toColor)
            .toolbar { toolbarContent }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Restore this version?"),
                      message: Text(#localized("Your current document will revert to the version from %@",
                                               viewModel.pastRevision.revisionDate)),
                      primaryButton: .default(Text("Restore"),
                                              action: { viewModel.restore() }),
                      secondaryButton: .cancel())
            }
            .showSpinner(viewModel.restoringItem)
    }
}

// MARK: - Utils {

extension DetailHistoryView {
    func borderColor(for element: KeyPath<ItemContent, some Hashable>) -> UIColor {
        viewModel.isDifferent(for: element) ? PassColor.signalWarning : PassColor.inputBorderNorm
    }

    func textColor(for element: KeyPath<ItemContent, some Hashable>) -> UIColor {
        viewModel.isDifferent(for: element) ? PassColor.signalWarning : PassColor.textNorm
    }

    func noteRow(item: ItemContent) -> some View {
        Group {
            if item.note.isEmpty {
                Text("Empty note")
                    .placeholderText()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextView(.constant(item.note))
                    .autoDetectDataTypes(.all)
                    // swiftlint:disable:next deprecated_foregroundcolor_modifier
                    .foregroundColor(PassColor.textNorm)
                    .isEditable(false)
            }
        }
    }

    func titleRow(itemContent: ItemContent) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemSquircleThumbnail(data: itemContent.thumbnailData(),
                                  pinned: false,
                                  size: .large)

            VStack(alignment: .leading, spacing: 4) {
                Text(itemContent.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .foregroundStyle(textColor(for: \.name).toColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 60)
        .padding(.bottom, 30)
    }

    func noteFields(item: ItemContent) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.note, color: viewModel.currentRevision.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Note")
                    .sectionTitleText()

                noteRow(item: item)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection(borderColor: borderColor(for: \.note))
    }
}

private extension DetailHistoryView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.arrowLeft,
                         iconColor: viewModel.currentRevision.contentData.type.normMajor2Color,
                         backgroundColor: viewModel.currentRevision.contentData.type.normMinor1Color,
                         accessibilityLabel: "Go back",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CapsuleLabelButton(icon: IconProvider.clockRotateLeft,
                               title: #localized("Restore"),
                               titleColor: viewModel.currentRevision.contentData.type.normMajor2Color,
                               backgroundColor: viewModel.currentRevision.contentData.type.normMinor1Color,
                               action: { showAlert = true })
        }
    }
}

private extension DetailHistoryView {
    var mainContainer: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                switch viewModel.currentRevision.contentData {
                case .note:
                    noteView
                case .login:
                    loginView
                case .creditCard:
                    creditCardView
                case .alias:
                    aliasView
                case .identity:
                    identityView
                }
            }
            .animation(.default, value: viewModel.selectedRevision)
            .padding(.bottom, DesignConstant.defaultPickerHeight)

            SegmentedPicker(selectedIndex: $viewModel.selectedItemIndex,
                            options: [viewModel.pastRevision.shortRevisionDate, #localized("Current")],
                            highlightTextColor: PassColor.textInvert,
                            mainColor: viewModel.currentRevision.contentData.type.normMajor2Color,
                            backgroundColor: viewModel.currentRevision.contentData.type.normMinor1Color)
        }
    }
}
