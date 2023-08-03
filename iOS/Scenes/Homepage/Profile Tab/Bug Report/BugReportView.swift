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
    @FocusState private var focused
    @StateObject private var viewModel = BugReportViewModel()
    var onError: (Error) -> Void
    var onSuccess: () -> Void

    init(onError: @escaping (Error) -> Void,
         onSuccess: @escaping () -> Void) {
        self.onError = onError
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationView {
            mainContainer
                .toolbar { toolbarContent }
                .navigationTitle("Report a problem")
                .navigationBarTitleDisplayMode(.inline)
                .showSpinner(viewModel.isSending)
                .onFirstAppear {
                    if #available(iOS 16, *) {
                        focused = true
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                            focused = true
                        }
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
        .accentColor(PassColor.interactionNorm.toColor) // Remove when dropping iOS 15
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
                        .foregroundColor(PassColor.textNorm.toColor)
                } else {
                    Text("I want to report a problem with...")
                        .foregroundColor(PassColor.textNorm.toColor)
                }

                Spacer()

                ItemDetailSectionIcon(icon: IconProvider.chevronDown)
            }
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity, alignment: .leading)
        })
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
    }
}

private extension BugReportView {
    @ViewBuilder
    var descriptionSection: some View {
        let title = "What went wrong?"
        let placeholder =
            // swiftlint:disable:next line_length
            "Please describe the problem in as much detail as you can. If there was an error message, let us know what it said."
        HStack(spacing: kItemDetailSectionPadding) {
            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text(title)
                    .font(.footnote)
                    .foregroundColor(PassColor.textNorm.toColor)

                // iOS 16 doesn't seem to support multiline placeholder
                // workaround by using a ZStack
                ZStack(alignment: .topLeading) {
                    if viewModel.description.isEmpty {
                        Text(placeholder)
                            .foregroundColor(PassColor.textHint.toColor)
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
            .contentShape(Rectangle())
            .onTapGesture {
                focused = true
            }
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
    }
}

private extension BugReportView {
    var includeLogsSection: some View {
        VStack {
            Toggle("Send error logs", isOn: $viewModel.shouldSendLogs)
                .foregroundColor(PassColor.textNorm.toColor)
                .padding(kItemDetailSectionPadding)
                .roundedEditableSection()
            // swiftlint:disable:next line_length
            Text("A log is a type of file that shows us the actions you took that led to an error. We'll only ever use them to help our engineers fix bugs.")
                .sectionTitleText()
        }
    }
}
