//
// NoteDetailView.swift
// Proton Pass - Created on 07/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

private enum TrimState: Sendable {
    case unknown, trimmed, notTrimmed

    var isTrimmed: Bool {
        if case .trimmed = self {
            true
        } else {
            false
        }
    }

    func maxHeight(for size: CGSize) -> CGFloat {
        switch self {
        case .trimmed, .unknown: size.height / 2
        case .notTrimmed: CGFloat.greatestFiniteMagnitude
        }
    }
}

struct NoteDetailView: View {
    @StateObject private var viewModel: NoteDetailViewModel
    @State private var trimState: TrimState = .unknown
    @Namespace private var bottomID

    init(viewModel: NoteDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                mainContent(for: proxy.size)
            }
        }
    }
}

private extension NoteDetailView {
    func mainContent(for size: CGSize) -> some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 0) {
                    ItemDetailTitleView(itemContent: viewModel.itemContent,
                                        vault: viewModel.vault?.vault)
                        .padding(.bottom, 40)

                    if viewModel.note.isEmpty {
                        Text("Empty note")
                            .placeholderText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        noteContent(for: size)
                    }

                    CustomFieldSections(itemContentType: viewModel.itemContent.type,
                                        fields: viewModel.customFields,
                                        isFreeUser: viewModel.isFreeUser,
                                        onSelectHiddenText: viewModel.copyHiddenText,
                                        onSelectTotpToken: viewModel.copyTOTPToken,
                                        onUpgrade: { viewModel.upgrade() })

                    if viewModel.showFileAttachmentsSection {
                        FileAttachmentsViewSection(files: viewModel.fileUiModels,
                                                   isFetching: viewModel.files.isFetching,
                                                   fetchError: viewModel.files.error,
                                                   handler: viewModel)
                            .padding(.top, 8)
                    }

                    ItemDetailHistorySection(itemContent: viewModel.itemContent,
                                             action: viewModel.showItemHistory)

                    ItemDetailMoreInfoSection(isExpanded: $viewModel.moreInfoSectionExpanded,
                                              itemContent: viewModel.itemContent,
                                              vault: viewModel.vault?.vault,
                                              onCopy: { viewModel.copyToClipboard(text: $0, message: $1) })
                        .padding(.top, 24)
                        .id(bottomID)
                }
                .padding()
                .animation(.default, value: viewModel.moreInfoSectionExpanded)
            }
            .onChange(of: viewModel.moreInfoSectionExpanded) { _ in
                withAnimation { value.scrollTo(bottomID, anchor: .bottom) }
            }
        }
        .itemDetailSetUp(viewModel)
    }

    func noteContent(for size: CGSize) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ReadOnlyTextView(viewModel.note,
                             maxHeight: trimState.maxHeight(for: size),
                             onRenderCompletion: { isTrimmed in
                                 if isTrimmed {
                                     trimState = .trimmed
                                 } else {
                                     trimState = .notTrimmed
                                 }
                             })
                             .padding(DesignConstant.sectionPadding)
                             .roundedDetailSection()

            if trimState.isTrimmed {
                Button(action: expandNote) {
                    Text("More")
                        .foregroundStyle(PassColor.noteInteractionNormMajor2.toColor)
                        .padding(.leading, DesignConstant.sectionPadding * 2)
                        .background(LinearGradient(stops:
                            [
                                Gradient.Stop(color: .clear, location: 0),
                                Gradient.Stop(color: PassColor.backgroundNorm.toColor, location: 1)
                            ],
                            startPoint: UnitPoint(x: 0, y: 0.5),
                            endPoint: UnitPoint(x: 0.41, y: 0.5)))
                }
                .padding(DesignConstant.sectionPadding)
            }
        }
        .onTapGesture(perform: expandNote)
    }

    func expandNote() {
        if trimState.isTrimmed {
            withAnimation {
                trimState = .notTrimmed
            }
        }
    }
}
