//
// SshKeyGenerator.swift
// Proton Pass - Created on 15/01/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Screens
import SwiftUI

struct SshKeyGenerator: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAdvancedOptions = false
    @State private var showTypeSelector = false
    @State private var comment = ""
    @State private var passphrase = ""
    @State private var type: SshKeyType = .default
    @FocusState private var focusedField: Field?
    let onConfirm: (SshKeyOptions) -> Void

    enum Field {
        case comment, passphrase
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Generate SSH key")
                    .navigationTitleText()
                Spacer()
            }

            OptionRow(action: { showTypeSelector.toggle() },
                      height: .tall,
                      content: {
                          VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 2) {
                              Text("SSH key type")
                                  .sectionTitleText()

                              Text(verbatim: type.title)
                                  .foregroundStyle(PassColor.textNorm)
                          }
                      },
                      trailing: { ChevronRight() })
                .roundedEditableSection()

            if showAdvancedOptions {
                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding) {
                    commentRow
                    PassSectionDivider()
                    passphraseRow
                }
                .padding(.vertical, DesignConstant.sectionPadding)
                .roundedEditableSection()
            } else {
                AdvancedOptionsSection(isShowingAdvancedOptions: $showAdvancedOptions)
                    .padding(.vertical)
            }

            HStack {
                CapsuleTextButton(title: #localized("Cancel"),
                                  titleColor: PassColor.textWeak,
                                  backgroundColor: PassColor.textDisabled,
                                  height: 44,
                                  action: dismiss.callAsFunction)

                CapsuleTextButton(title: #localized("Confirm"),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.loginInteractionNormMajor1,
                                  height: 44,
                                  action: {
                                      onConfirm(.init(type: type,
                                                      comment: comment,
                                                      passphrase: passphrase))
                                      dismiss()
                                  })
            }
            .padding(.vertical)
        }
        .padding()
        .animation(.default, value: showAdvancedOptions)
        .presentationDragIndicator(.visible)
        .background(PassColor.backgroundNorm)
        .accentColor(PassColor.interactionNorm)
        .tint(PassColor.interactionNorm)
        .fittedPresentationDetent(onHeightChanged: nil)
        .sheet(isPresented: $showTypeSelector) {
            SshKeyTypeList(type: $type)
        }
    }
}

private extension SshKeyGenerator {
    var commentRow: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Comment")
                        .editableSectionTitleText(for: comment)
                    TextField("Add a comment", text: $comment)
                        .focused($focusedField, equals: .comment)
                        .foregroundStyle(PassColor.textNorm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ClearTextButton(text: $comment)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: comment.isEmpty)
    }

    var passphraseRow: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Passphrase")
                        .editableSectionTitleText(for: passphrase)
                    TextField("Add a passphrase", text: $passphrase)
                        .focused($focusedField, equals: .passphrase)
                        .foregroundStyle(PassColor.textNorm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ClearTextButton(text: $passphrase)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: passphrase.isEmpty)
    }
}

private struct SshKeyTypeList: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var type: SshKeyType

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("SSH key type")
                    .navigationTitleText()
                Spacer()
            }

            ForEach(SshKeyType.allCases, id: \.self) { type in
                let isSelected = self.type == type
                SelectableOptionRow(action: { self.type = type; dismiss() },
                                    height: .compact,
                                    content: {
                                        Text(verbatim: type.title)
                                            .foregroundStyle(isSelected ?
                                                PassColor.interactionNormMajor2 : PassColor
                                                .textNorm)
                                    },
                                    isSelected: isSelected)
                PassSectionDivider()
            }
        }
        .padding()
        .background(PassColor.backgroundWeak)
        .presentationDragIndicator(.visible)
        .fittedPresentationDetent(onHeightChanged: nil)
    }
}
