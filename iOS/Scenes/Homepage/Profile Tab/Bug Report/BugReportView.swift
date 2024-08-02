//
// BugReportView.swift
// Proton Pass - Created on 28/06/2023.
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

import DesignSystem
import Macro
import PhotosUI
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused
    @StateObject private var viewModel = BugReportViewModel()
    var onError: (any Error) -> Void
    var onSuccess: () -> Void
    @State var isShowing = false

    init(onError: @escaping (any Error) -> Void,
         onSuccess: @escaping () -> Void) {
        self.onError = onError
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack {
            mainContainer
                .toolbar { toolbarContent }
                .navigationTitle("Report a problem")
                .navigationBarTitleDisplayMode(.inline)
                .showSpinner(viewModel.actionInProcess)
                .onFirstAppear {
                    focused = true
                }
        }
        .onChange(of: viewModel.hasSent) { value in
            if value {
                // Do not automatically dismiss here but let the coordinator dismiss
                // Because we need to show a banner after the view is fully dismissed
                onSuccess()
            }
        }
        .onReceive(viewModel.$error) { error in
            if let error {
                onError(error)
            }
        }
    }
}

private extension BugReportView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CircleButton(icon: IconProvider.paperPlane,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Send bug report") {
                viewModel.send()
            }.disabled(viewModel.cantSend)
        }
    }
}

private extension BugReportView {
    var mainContainer: some View {
        ScrollView {
            VStack {
                objectSection
                descriptionSection

                includeLogsSection
                includeFileSection
                if !viewModel.currentFiles.isEmpty {
                    selectedFiles
                }

                Spacer()
            }
            .padding()
            .frame(maxHeight: .infinity)
        }
        .tint(PassColor.interactionNorm.toColor)
        .background(PassColor.backgroundNorm.toColor)
    }
}

private extension BugReportView {
    var objectSection: some View {
        Menu(content: {
            ForEach(BugReportObject.allCases, id: \.self) { object in
                Button(action: {
                    viewModel.object = object
                }, label: {
                    Text(object.description)
                })
            }
        }, label: {
            HStack {
                if let object = viewModel.object {
                    Text(object.description)
                        .foregroundStyle(PassColor.textNorm.toColor)
                } else {
                    Text("I want to report a problem with...")
                        .foregroundStyle(PassColor.textNorm.toColor)
                }

                Spacer()

                ItemDetailSectionIcon(icon: IconProvider.chevronDown)
            }
            .contentShape(.rect)
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
    }
}

private extension BugReportView {
    @ViewBuilder
    var descriptionSection: some View {
        let title = #localized("What went wrong?")
        let placeholder =
            // swiftlint:disable:next line_length
            #localized("Please describe the problem in as much detail as you can. If there was an error message, let us know what it said.")
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(PassColor.textNorm.toColor)

                // iOS 16 doesn't seem to support multiline placeholder
                // workaround by using a ZStack
                ZStack(alignment: .topLeading) {
                    if viewModel.description.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(PassColor.textHint.toColor)
                    }

                    TextEditorWithPlaceholder(text: $viewModel.description,
                                              focusedField: $focused,
                                              field: true,
                                              placeholder: "",
                                              minHeight: 150)
                }
                .animation(.default, value: viewModel.description.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .onTapGesture {
                focused = true
            }
        }
        .padding(DesignConstant.sectionPadding)
        .roundedEditableSection()
    }
}

private extension BugReportView {
    var includeLogsSection: some View {
        VStack {
            Toggle("Send logs", isOn: $viewModel.shouldSendLogs)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(DesignConstant.sectionPadding)
                .roundedEditableSection()
            // swiftlint:disable:next line_length
            Text("A log is a type of file that shows us the actions you took that led to an error. We'll only ever use them to help our engineers fix bugs.")
                .sectionTitleText()
        }
    }
}

private extension BugReportView {
    var includeFileSection: some View {
        VStack {
            HStack {
                CapsuleTextButton(title: #localized("Add a File"),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.interactionNorm,
                                  action: { isShowing.toggle() })
                    .fileImporter(isPresented: $isShowing,
                                  allowedContentTypes: [.item],
                                  allowsMultipleSelection: true) { results in
                        viewModel.addFiles(files: results)
                    }

                PhotosPicker("Select Content",
                             selection: $viewModel.selectedContent,
                             maxSelectionCount: 2,
                             photoLibrary: .shared())
                    .font(.callout)
                    .foregroundStyle(PassColor.textInvert.toColor)
                    .frame(height: 40)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .background(PassColor.interactionNorm.toColor)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
            .foregroundStyle(PassColor.textNorm.toColor)
            .padding(DesignConstant.sectionPadding)
            .roundedEditableSection()

            Text("Add relevant files or images to the report")
                .sectionTitleText()
        }
    }
}

private extension BugReportView {
    var selectedFiles: some View {
        VStack(alignment: .leading) {
            Text("Added files")
                .font(.callout.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignConstant.sectionPadding)

            VStack(alignment: .leading) {
                FlowLayout(items: Array(viewModel.currentFiles.keys),
                           viewMapping: { element in
                               HStack(alignment: .center, spacing: 10) {
                                   Text(element)
                                       .lineLimit(1)
                               }
                               .font(.callout)
                               .foregroundStyle(PassColor.textNorm.toColor)
                               .padding(.horizontal, 10)
                               .padding(.vertical, 8)
                               .background(PassColor.interactionNormMinor1.toColor)
                               .cornerRadius(9)
                               .contentShape(.rect)
                           })
            }

            CapsuleTextButton(title: #localized("Clear all files"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNorm,
                              action: { viewModel.clearAllAddedFiles() })
        }
        .foregroundStyle(PassColor.textNorm.toColor)
        .frame(maxHeight: .infinity)
    }
}
