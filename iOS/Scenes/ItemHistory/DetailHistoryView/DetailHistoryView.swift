//
//
// DetailHistoryView.swift
// Proton Pass - Created on 11/01/2024.
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

struct DetailHistoryView: View {
    @StateObject var viewModel: DetailHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0

    var body: some View {
        mainContainer
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(DesignConstant.sectionPadding)
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundNorm.toColor)
            .toolbar { toolbarContent }
    }
}

private extension DetailHistoryView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.arrowLeft,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            CapsuleLabelButton(icon: IconProvider.clockRotateLeft,
                               title: #localized("Restore"),
                               titleColor: PassColor.interactionNormMajor2,
                               backgroundColor: PassColor.interactionNormMinor1,
                               action: {})
//            CircleButton(icon: IconProvider.arrowLeft,
//                         iconColor: PassColor.interactionNormMajor2,
//                         backgroundColor: PassColor.interactionNormMinor1,
//                         action: dismiss.callAsFunction)
//            DisablableCapsuleTextButton(title: #localized("Continue"),
//                                        titleColor: PassColor.textInvert,
//                                        disableTitleColor: PassColor.textHint,
//                                        backgroundColor: PassColor.interactionNormMajor1,
//                                        disableBackgroundColor: PassColor.interactionNormMinor1,
//                                        disabled: !viewModel.canContinue,
//                                        action: { viewModel.goToNextStep = true })
        }
    }
}

private extension DetailHistoryView {
    var mainContainer: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                Text("History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .padding(.horizontal, DesignConstant.sectionPadding)

//                if let lastUsed = viewModel.lastUsedTime {
//                    header(lastUsed: lastUsed)
//                }
//                if viewModel.state == .loading {
//                    progressView
//                } else if !viewModel.state.history.isEmpty {
//                    historyListView
//                }
            }
//            .animation(.default, value: viewModel.state)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PassColor.backgroundNorm.toColor)

            SegmentedPicker(selectedIndex: $selectedIndex,
                            options: [viewModel.revision.shortRevisionDate, #localized("Current")])
        }
    }
}

// struct DetailHistoryView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailHistoryView()
//    }
// }
