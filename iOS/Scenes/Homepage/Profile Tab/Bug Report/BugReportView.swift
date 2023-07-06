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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = BugReportViewModel()
    var onError: (Error) -> Void
    var onSuccess: () -> Void

    private enum Field {
        case title, description
    }

    var body: some View {
        NavigationView {
            mainContainer
                .toolbar { toolbarContent }
                .navigationTitle("Bug Report")
                .navigationBarTitleDisplayMode(.inline)
        }
        .onFirstAppear {
            if #available(iOS 16, *) {
                focusedField = .title
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    focusedField = .title
                }
            }
        }
        .navigationViewStyle(.stack)
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
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CircleButton(icon: IconProvider.paperPlane,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1) {
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
                Spacer()
            }
            .padding()
            .frame(maxHeight: .infinity)
        }
        .background(PassColor.backgroundNorm.toColor)
        .overlay {
            if viewModel.isSending {
                ProgressView()
            }
        }
    }
}

private extension BugReportView {
    var objectSection: some View {
        VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
            Text("Object of your report")
                .sectionTitleText()
            TextField("Object", text: $viewModel.title)
                .onSubmit {
                    focusedField = .description
                }
                .focused($focusedField, equals: .title)
                .contentShape(Rectangle())
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension BugReportView {
    var descriptionSection: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Description")
                    .sectionTitleText()

                TextEditorWithPlaceholder(text: $viewModel.feedback,
                                          focusedField: $focusedField,
                                          field: .description,
                                          placeholder: "Give us a feedback")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.feedback.isEmpty {
                Button(action: {
                    viewModel.feedback = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
    }
}

private extension BugReportView {
    var includeLogsSection: some View {
        Toggle("Should include logs", isOn: $viewModel.shouldSendLogs)
            .padding(kItemDetailSectionPadding)
            .roundedEditableSection()
    }
}
