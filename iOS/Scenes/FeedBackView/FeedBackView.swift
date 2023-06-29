//
// FeedBackView.swift
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

struct FeedBackView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FeedBackField?
    @StateObject private var viewModel = FeedBackViewModel()

    private enum FeedBackField {
        case title, description
    }

    var body: some View {
        NavigationView {
            mainContainer
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        CircleButton(icon: IconProvider.chevronDown,
                                     iconColor: ItemContentType.note.normMajor2Color,
                                     backgroundColor: ItemContentType.note.normMinor1Color) {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        CircleButton(icon: IconProvider.paperPlane,
                                     iconColor: ItemContentType.note.normMajor2Color,
                                     backgroundColor: ItemContentType.note.normMinor1Color) {
                            viewModel.send()
                        }.disabled(viewModel.cantSendFeedBack)
                    }
                }
                .onChange(of: viewModel.hasSentFeedBack) { value in
                    guard value else {
                        return
                    }
                    dismiss()
                }
                .overlay {
                    if viewModel.isSending {
                        ProgressView("Sending ...")
                    } else {
                        EmptyView()
                    }
                }
                .background(Color(uiColor: PassColor.backgroundNorm))
                .navigationTitle("Feedback")
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
    }
}

private extension FeedBackView {
    var mainContainer: some View {
        VStack {
            feedbackObjectField
            feedbackTag
            feedBackDescription
            Spacer()
        }.padding()
    }
}

private extension FeedBackView {
    @ViewBuilder
    var feedbackObjectField: some View {
        TextField("Object", text: $viewModel.title)
            .onSubmit {
                focusedField = .description
            }
            .focused($focusedField, equals: .title)
            .padding(kItemDetailSectionPadding)
            .roundedEditableSection()
            .contentShape(Rectangle())
    }
}

private extension FeedBackView {
    @ViewBuilder
    var feedbackTag: some View {
        Picker("Please choose a tag", selection: $viewModel.selectedTag) {
            ForEach(FeedBackTag.allCases, id: \.self) {
                Text($0.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }
}

private extension FeedBackView {
    @ViewBuilder
    var feedBackDescription: some View {
        HStack(spacing: kItemDetailSectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.note)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Description")
                    .sectionTitleText()

                feedBackDescriptionField
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !viewModel.feedBack.isEmpty {
                Button(action: {
                    viewModel.feedBack = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
    }
}

private extension FeedBackView {
    @ViewBuilder
    var feedBackDescriptionField: some View {
        if #available(iOS 16.0, *) {
            TextField("Give us a feedback", text: $viewModel.feedBack, axis: .vertical)
                .focused($focusedField, equals: .description)
                .scrollContentBackground(.hidden)
                .foregroundColor(Color(uiColor: PassColor.textNorm))
                .font(Font(UIFont.body.weight(.regular)))
        } else {
            TextView($viewModel.feedBack, onCommit: {})
                .placeholder("Give us a feedback")
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(PassColor.textNorm)
                .focused($focusedField, equals: .description)
        }
    }
}

struct FeedBackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedBackView()
    }
}
