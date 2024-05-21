//
//
// PublicLinkView.swift
// Proton Pass - Created on 16/05/2024.
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
import SwiftUI

struct PublicLinkView: View {
    @StateObject private var viewModel: PublicLinkViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: PublicLinkViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        mainContainer
            .navigationStackEmbeded()
    }
}

private extension PublicLinkView {
    var mainContainer: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            itemHeader

            if let link = viewModel.link {
                shareLink(link: link)
            } else {
                createLink
            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .showSpinner(viewModel.loading)
        .animation(.default, value: viewModel.link)
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm.toColor,
                           for: .navigationBar)
        .navigationTitle(viewModel.link != nil ? "Share a link to this item" : "Create a public link to this item")
    }
}

private extension PublicLinkView {
    var itemHeader: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemSquircleThumbnail(data: viewModel.itemContent.thumbnailData(),
                                  pinned: viewModel.itemContent.item.pinned,
                                  size: .large)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.itemContent.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 60)
        .padding(.vertical, 20)
    }
}

private extension PublicLinkView {
    var createLink: some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            HStack {
                Text("Link expires after")
                    // swiftlint:disable:next deprecated_foregroundcolor_modifier
                    .foregroundColor(PassColor.textNorm.toColor)
                    + Text(verbatim: ":")
                    // swiftlint:disable:next deprecated_foregroundcolor_modifier
                    .foregroundColor(PassColor.textNorm.toColor)

                Spacer()
                Picker("Link expires after", selection: $viewModel.selectedTime) {
                    ForEach(viewModel.timeOptions) { option in
                        Text(option.label).tag(option)
                            .fontWeight(.medium)
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                }
                .tint(viewModel.itemContent.contentData.type.normMajor2Color.toColor)
            }

            VStack {
                Toggle("Add a maximum number of reads", isOn: $viewModel.addNumberOfReads)
                    .toggleStyle(SwitchToggleStyle.pass)

                if viewModel.addNumberOfReads {
                    TextField("Max number of reads", text: $viewModel.maxNumber)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .keyboardType(.numberPad)
                        .padding(DesignConstant.sectionPadding)
                        .roundedDetailSection()
                }
            }

            Spacer()
            CapsuleTextButton(title: "Create link",
                              titleColor: viewModel.itemContent.contentData.type.normMajor2Color,
                              backgroundColor: viewModel.itemContent.contentData.type.normMinor1Color,
                              action: { viewModel.createLink() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension PublicLinkView {
    @ViewBuilder
    func shareLink(link: SharedPublicLink) -> some View {
        VStack(spacing: DesignConstant.sectionPadding) {
            HStack(spacing: DesignConstant.sectionPadding) {
                Text(verbatim: link.url)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: { viewModel.copyLink() })
                    .roundedDetailSection()

                Button { viewModel.copyLink() } label: {
                    Text("Copy Link")
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .padding()
                        .roundedDetailSection(backgroundColor: PassColor.interactionNormMinor1)
                }
                .buttonStyle(.plain)

                ShareLink(item: link.url) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                }
            }
            if let relativeTimeRemaining = link.relativeTimeRemaining {
                Text("This link is available for the next \(relativeTimeRemaining)")
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
