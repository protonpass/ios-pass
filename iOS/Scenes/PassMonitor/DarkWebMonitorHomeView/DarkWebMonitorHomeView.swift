//
//
// DarkWebMonitorHomeView.swift
// Proton Pass - Created on 16/04/2024.
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
import ProtonCoreUIFoundations
import SwiftUI

struct DarkWebMonitorHomeView: View {
    @StateObject var viewModel: DarkWebMonitorHomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
//        mainContainer.if(isSheet) { view in
        NavigationStack {
            mainContainer
        }
//        }
    }
}

private extension DarkWebMonitorHomeView {
    var mainContainer: some View {
        VStack {
            Text("Last check: \(viewModel.getCurrentLocalizedDateTime())")
                .foregroundStyle(PassColor.textNorm.toColor)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)

            LazyVStack(spacing: 0) {
//                if viewModel.showSections {
//                    itemsSections(sections: viewModel.sectionedData)
//                } else {
//                    itemsList(items: viewModel.sectionedData.flatMap(\.value))
//                }
//                Spacer()
            }
        }.padding(.horizontal, DesignConstant.sectionPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar { toolbarContent }
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
//            .showSpinner(viewModel.loading)
            .navigationTitle("Dark Web Monitoring")
    }
}

private extension DarkWebMonitorHomeView {
    var customEmails: some View {
        Text("")
//        ForEach(sections.keys.sorted(by: >), id: \.self) { key in
        ////            Section(content: {
        ////                itemsList(items: sections[key] ?? [])
        ////            }, header: {
        ////                HStack {
        ////                    "Custom"
        ////                }
        //////                Group {
        ////////                    if let iconName = key.iconName {
        ////////                        Label(key.title, systemImage: iconName)
        ////////                    } else {
        ////////                        Text(key.title)
        ////////                    }
        //////                }
        ////                .font(.callout)
        ////                .foregroundColor(key.color)
        ////                .frame(maxWidth: .infinity, alignment: .leading)
        ////                .padding(.top, DesignConstant.sectionPadding)
        ////            })
//        }
    }
}

private extension DarkWebMonitorHomeView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
//            CircleButton(icon: isSheet ? IconProvider.chevronDown : IconProvider.chevronLeft,
//                         iconColor: PassColor.loginInteractionNormMajor2,
//                         backgroundColor: PassColor.loginInteractionNormMinor1,
//                         accessibilityLabel: "Close") {
//                dismiss()
//            }
            CircleButton(icon: IconProvider.chevronLeft,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1,
                         accessibilityLabel: "Close") {
                dismiss()
            }
        }
    }
}
