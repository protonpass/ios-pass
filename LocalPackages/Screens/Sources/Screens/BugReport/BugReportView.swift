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

import Core
import DesignSystem
import Macro
import PhotosUI
import ProtonCoreUIFoundations
import SwiftUI

public struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused
    @State private var viewModel = BugReportViewModel()
    @State private var showFilePicker = false
    @State private var showPhotoPicker = false
    @State private var contentWidth: CGFloat = 0
    var onSuccess: () -> Void

    public init(onSuccess: @escaping () -> Void) {
        self.onSuccess = onSuccess
    }

    public var body: some View {
        NavigationStack {
            mainContainer
                .toolbar { toolbarContent }
                .navigationTitle(Text("Report a problem", bundle: .module))
                .showSpinner(viewModel.actionInProcess)
                .onFirstAppear {
                    focused = true
                }
        }
        .onChange(of: viewModel.hasSent) { _, value in
            if value {
                // Do not automatically dismiss here but let the coordinator dismiss
                // Because we need to show a banner after the view is fully dismissed
                onSuccess()
            }
        }
        .onChange(of: viewModel.selectedPhotos) { _, value in
            viewModel.addPhotos(value)
        }
        .fileImporter(isPresented: $showFilePicker,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: true) { files in
            viewModel.addFiles(files)
        }
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $viewModel.selectedPhotos,
                      maxSelectionCount: Constants.Report.maxFileCount)
    }
}

private extension BugReportView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            CapsuleTextButton(title: #localized("Send", bundle: .module),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNorm,
                              action: viewModel.send)
        }
    }
}

@MainActor
private extension BugReportView {
    var mainContainer: some View {
        ScrollView {
            VStack {
                objectSection
                descriptionSection
                    .padding(.top, DesignConstant.sectionPadding)
                characterCountSection
                logsSection
                    .padding(.vertical, DesignConstant.sectionPadding)
                attachmentsSection
                Spacer()
            }
            .onGeometryChange(for: CGFloat.self, of: { $0.size.width }, action: { contentWidth = $0 })
            .padding()
            .frame(maxHeight: .infinity)
            .animation(.default, value: viewModel.currentFiles)
        }
        .tint(PassColor.interactionNorm)
        .background(PassColor.backgroundNorm)
    }

    func pickerLabel(_ title: String) -> some View {
        Label(title: { Text(title) },
              icon: { Image(systemName: "chevron.up.chevron.down") })
            .fontWeight(.bold)
            .foregroundStyle(PassColor.interactionNormMajor2)
            .labelStyle(.rightIcon)
            .padding(DesignConstant.sectionPadding)
            .roundedEditableSection(backgroundColor: PassColor.interactionNormMinor1,
                                    borderColor: .clear)
    }
}

@MainActor
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
                pickerLabel(viewModel.object?.description ?? #localized("Select reason", bundle: .module))
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .animation(.default, value: viewModel.object)
        })
    }
}

@MainActor
private extension BugReportView {
    @ViewBuilder
    var descriptionSection: some View {
        let title = #localized("What went wrong?", bundle: .module)
        let placeholder =
            // swiftlint:disable:next line_length
            #localized("Please describe the problem in as much detail as you can. If there was an error message, let us know what it said.",
                       bundle: .module)
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(PassColor.textNorm)

                // iOS 16 doesn't seem to support multiline placeholder
                // workaround by using a ZStack
                ZStack(alignment: .topLeading) {
                    if viewModel.description.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(PassColor.textHint)
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

    var characterCountSection: some View {
        Text(verbatim: "(\(viewModel.description.count)/\(Constants.Report.maxCharCount))")
            .font(.footnote)
            .foregroundStyle(viewModel.description.count <= Constants.Report.maxCharCount ?
                PassColor.textWeak : PassColor.signalDanger)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
private extension BugReportView {
    var logsSection: some View {
        VStack {
            Toggle(isOn: $viewModel.shouldSendLogs) {
                Text("Logs", bundle: .module)
                    .foregroundStyle(PassColor.textNorm)
            }

            // swiftlint:disable:next line_length
            Text("A log is a type of file that shows us the actions you took that led to an error. We'll only ever use them to help our engineers fix bugs.",
                 bundle: .module)
                .sectionTitleText()
        }
    }
}

@MainActor
private extension BugReportView {
    var attachmentsSection: some View {
        VStack {
            HStack {
                Text("Attachments", bundle: .module)
                    .foregroundStyle(PassColor.textNorm)
                Spacer()
                Menu(content: {
                    Button(action: {
                        showPhotoPicker = true
                    }, label: {
                        Text("Photos or videos", bundle: .module)
                    })

                    Button(action: {
                        showFilePicker = true
                    }, label: {
                        Text("Files", bundle: .module)
                    })
                }, label: {
                    pickerLabel(#localized("Attach", bundle: .module))
                })
            }

            FlowLayout(spacing: 8) {
                ForEach(Array(viewModel.currentFiles.keys), id: \.self) { key in
                    view(for: key)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    func view(for fileName: String) -> some View {
        Label(title: {
            Text(fileName)
                .font(.callout)
                .foregroundStyle(PassColor.textNorm)
                .lineLimit(1)
                .truncationMode(.middle)
        }, icon: {
            Button(action: {
                viewModel.removeFile(fileName)
            }, label: {
                IconProvider.crossCircle
                    .resizable()
                    .foregroundStyle(PassColor.interactionNormMajor2)
                    .frame(width: 18, height: 18)
            })
        })
        .labelStyle(.rightIcon)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: contentWidth > 0 ? contentWidth : nil)
        .overlay(RoundedRectangle(cornerRadius: 4)
            .stroke(PassColor.backgroundMedium, lineWidth: 1))
    }
}
