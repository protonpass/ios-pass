//
// FeedbackView.swift
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

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @StateObject private var viewModel = FeedbackViewModel()
    var displayAlert: (Error) -> Void

    private enum Field {
        case title, description
    }

    var body: some View {
        NavigationView {
            mainContainer
                .toolbar {
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
                        }.disabled(viewModel.cantSendFeedBack)
                    }
                }
                .onChange(of: viewModel.hasSentFeedBack) { value in
                    if value {
                        dismiss()
                    }
                }
                .overlay {
                    if viewModel.isSending {
                        ProgressView()
                    }
                }
                .background(Color(uiColor: PassColor.backgroundNorm))
                .navigationTitle("Feedback")
                .navigationBarTitleDisplayMode(.inline)
                .onReceive(viewModel.$error) { error in
                    guard let error else {
                        return
                    }
                    displayAlert(error)
                }
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
    }
}

private extension FeedbackView {
    var mainContainer: some View {
        VStack {
            feedbackObjectField
            Toggle("Should include logs", isOn: $viewModel.shouldSendLogs)
                .padding(kItemDetailSectionPadding)
                .roundedEditableSection()
//            feedbackTag
            feedBackDescription
            Spacer()
        }.padding()
    }
}

private extension FeedbackView {
    @ViewBuilder
    var feedbackObjectField: some View {
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

private extension FeedbackView {
    @ViewBuilder
    var feedbackTag: some View {
        Picker("Please choose a tag", selection: $viewModel.selectedTag) {
            ForEach(FeedbackTag.allCases, id: \.self) {
                Text($0.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }
}

private extension FeedbackView {
    @ViewBuilder
    var feedBackDescription: some View {
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
