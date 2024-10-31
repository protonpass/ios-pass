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

private extension BugReportView {
    enum ValidationError: LocalizedError {
        case missingReason
        case shortDescription

        var errorDescription: String? {
            switch self {
            case .missingReason:
                #localized("Please select a reason")
            case .shortDescription:
                #localized("Please provide us with more details in the description")
            }
        }
    }
}

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused
    @StateObject private var viewModel = BugReportViewModel()
    @State private var validationError: ValidationError?
    @State private var showFilePicker = false
    @State private var showPhotoPicker = false
    var onError: (any Error) -> Void
    var onSuccess: () -> Void

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
        .fileImporter(isPresented: $showFilePicker,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: true) { files in
            viewModel.addFiles(files)
        }
        .photosPicker(isPresented: $showPhotoPicker,
                      selection: $viewModel.selectedPhotos,
                      maxSelectionCount: 4)
        .alert(isPresented: $validationError.mappedToBool(),
               error: validationError,
               actions: { Button(action: {}, label: { Text("OK") }) })
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
            CapsuleTextButton(title: #localized("Send"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNorm) {
                if viewModel.object == nil {
                    validationError = .missingReason
                } else if viewModel.description.count < 10 {
                    validationError = .shortDescription
                } else {
                    viewModel.send()
                }
            }
        }
    }
}

@MainActor
private extension BugReportView {
    var mainContainer: some View {
        ScrollView {
            VStack(spacing: DesignConstant.sectionPadding * 1.5) {
                objectSection
                descriptionSection
                logsSection
                attachmentsSection
                Spacer()
            }
            .padding()
            .frame(maxHeight: .infinity)
            .animation(.default, value: viewModel.currentFiles)
        }
        .tint(PassColor.interactionNorm.toColor)
        .background(PassColor.backgroundNorm.toColor)
    }

    func pickerLabel(_ title: String) -> some View {
        Label(title: { Text(title) },
              icon: { Image(systemName: "chevron.up.chevron.down") })
            .fontWeight(.bold)
            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
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
                pickerLabel(viewModel.object?.description ?? #localized("Select reason"))
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

@MainActor
private extension BugReportView {
    var logsSection: some View {
        VStack {
            Toggle("Logs", isOn: $viewModel.shouldSendLogs)
                .foregroundStyle(PassColor.textNorm.toColor)
            // swiftlint:disable:next line_length
            Text("A log is a type of file that shows us the actions you took that led to an error. We'll only ever use them to help our engineers fix bugs.")
                .sectionTitleText()
        }
    }
}

@MainActor
private extension BugReportView {
    var attachmentsSection: some View {
        VStack {
            HStack {
                Text("Attachments")
                    .foregroundStyle(PassColor.textNorm.toColor)
                Spacer()
                Menu(content: {
                    Button(action: {
                        showPhotoPicker = true
                    }, label: {
                        Text("Screenshot")
                    })

                    Button(action: {
                        showFilePicker = true
                    }, label: {
                        Text("File")
                    })
                }, label: {
                    pickerLabel(#localized("Attach"))
                })
            }

            VStack(alignment: .leading) {
                AnyLayout(FlowLayout(spacing: 8)) {
                    ForEach(Array(viewModel.currentFiles.keys), id: \.self) { key in
                        view(for: key)
                    }
                }
            }
        }
    }

    func view(for fileName: String) -> some View {
        Label(title: {
            Text(fileName)
                .font(.callout)
                .foregroundStyle(PassColor.textNorm.toColor)
        }, icon: {
            Button(action: {
                viewModel.removeFile(fileName)
            }, label: {
                Image(uiImage: IconProvider.crossCircle)
                    .resizable()
                    .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                    .frame(width: 18, height: 18)
            })
        })
        .labelStyle(.rightIcon)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .overlay(RoundedRectangle(cornerRadius: 4)
            .stroke(PassColor.backgroundMedium.toColor, lineWidth: 1))
    }
}
