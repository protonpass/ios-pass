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
        VStack {
            itemHeader

            if let link = viewModel.link {
                shareLink(link: link)
            } else {
                createLink
            }

//            VStack {
//                Text("Link expires after:")
//
//                Picker("Link expires after", selection: $viewModel.selectedTime) {
//                    ForEach(viewModel.timeOptions) { option in
//                        Text(option.label).tag(option)
//                    }
//                }
//                .pickerStyle(.menu)
//
            ////                Text("Selected Time in Seconds: \(viewModel.selectedTime.seconds)")
//            }
//            mainTitle
//                .padding(.top)
//            VStack(spacing: DesignConstant.sectionPadding) {
//                protonAddressesSection
//                aliasesSection
//                customEmailsSection
//                suggestedEmailsSection
//            }
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .padding(.bottom, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .showSpinner(viewModel.loading)
        .animation(.default, value: viewModel.link)
//        .animation(.default, value: viewModel.customEmailsState)
//        .animation(.default, value: viewModel.suggestedEmailsState)
        .toolbar { toolbarContent }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(PassColor.backgroundNorm.toColor,
                           for: .navigationBar)
//        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.link != nil ? "Share a link to this item" : "Create a public link to this item")
//        .alert(Text("Data Security"),
//               isPresented: $showDataSecurityExplanation,
//               actions: { Button("OK", action: {}) },
//               message: {
//            // swiftlint:disable:next line_length
//            Text("Proton never shares your information with third parties. All data comes from searches for the
//            appearance of Proton domains on the dark web.")
//        })
//        .alert(Text(verbatim: "✅"),
//               isPresented: $showNoBreachesAlert,
//               actions: { Button("OK", action: {}) },
//               message: { Text("None of your email addresses or aliases appear in a data breach") })
//        .alert(Text(verbatim: "⚠️"),
//               isPresented: $showBreachesFoundAlert,
//               actions: { Button("OK", action: {}) },
//               message: { Text("One of your email addresses or aliases appear in a data breach") })
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
        .padding(.bottom, 40)
    }
}

private extension PublicLinkView {
    @ViewBuilder
    var createLink: some View {
        VStack {
            Text("Link expires after:")

            Picker("Link expires after", selection: $viewModel.selectedTime) {
                ForEach(viewModel.timeOptions) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)

            Spacer()
            CapsuleTextButton(title: "Create link",
                              titleColor: viewModel.itemContent.contentData.type.normMajor2Color,
                              backgroundColor: viewModel.itemContent.contentData.type.normMinor1Color,
                              action: { viewModel.createLink() })
                .padding(.horizontal, DesignConstant.sectionPadding)
        }
    }
}

private extension PublicLinkView {
    @ViewBuilder
    func shareLink(link: String) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            Text(verbatim: link)
//            ItemDetailSectionIcon(icon: viewModel.isAlias ? IconProvider.alias : IconProvider.envelope,
//                                  color: iconTintColor)
//
//            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//                Text("Email address")
//                    .sectionTitleText()
//
//                if viewModel.email.isEmpty {
//                    Text("Empty")
//                        .placeholderText()
//                } else {
//                    Text(viewModel.email)
//                        .sectionContentText()
//
//                    if viewModel.isAlias {
//                        Button { viewModel.showAliasDetail() } label: {
//                            Text("View alias")
//                                .font(.callout)
//                                .foregroundStyle(viewModel.itemContent.type.normMajor2Color.toColor)
//                                .underline(color: viewModel.itemContent.type.normMajor2Color.toColor)
//                        }
//                        .padding(.top, 8)
//                    }
//                }
//            }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: { viewModel.copyLink() })
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .roundedDetailSection()
//        VStack {
//
//
//
//
//            Text("Link expires after:")
//
//            Picker("Link expires after", selection: $viewModel.selectedTime) {
//                ForEach(viewModel.timeOptions) { option in
//                    Text(option.label).tag(option)
//                }
//            }
//            .pickerStyle(.menu)
//
//            Spacer()
//            CapsuleTextButton(title: "Create link",
//                              titleColor: viewModel.itemContent.contentData.type.normMajor2Color,
//                              backgroundColor:  viewModel.itemContent.contentData.type.normMinor1Color,
//                              action: { viewModel.createLink() })
//                .padding(.horizontal, DesignConstant.sectionPadding)
//        }
    }
}

private extension PublicLinkView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }
//
//        if let aliasBreaches = viewModel.aliasBreachesState.fetchedObject,
//           let customEmailBreaches = viewModel.customEmailsState.fetchedObject {
//            let totalBreaches = aliasBreaches.breachCount + customEmailBreaches.breachCount + viewModel
//                .userBreaches.emailsCount
//            let noBreaches = totalBreaches == 0
//            let icon: UIImage = noBreaches ? IconProvider.checkmarkCircleFilled : IconProvider
//                .exclamationCircleFilled
//            let iconColor = noBreaches ? PassColor.cardInteractionNormMajor2 : PassColor
//                .passwordInteractionNormMajor2
//            let backgroundColor = noBreaches ? PassColor.cardInteractionNormMinor2 : PassColor
//                .passwordInteractionNormMinor2
//            ToolbarItem(placement: .navigationBarTrailing) {
//                CircleButton(icon: icon, iconColor: iconColor, backgroundColor: backgroundColor) {
//                    if noBreaches {
//                        showNoBreachesAlert.toggle()
//                    } else {
//                        showBreachesFoundAlert.toggle()
//                    }
//                }
//            }
//        }
    }
}

// struct PublicLinkView_Previews: PreviewProvider {
//    static var previews: some View {
//        PublicLinkView()
//    }
// }
