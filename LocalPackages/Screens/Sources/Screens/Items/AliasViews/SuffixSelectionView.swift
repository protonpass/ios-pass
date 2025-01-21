//
// SuffixSelectionView.swift
// Proton Pass - Created on 02/08/2024.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct SuffixSelectionView: View {
    @Binding var selection: SuffixSelection
    let showTip: Bool
    let onAddDomain: () -> Void
    let onDismissTip: () -> Void
    let onDismiss: () -> Void

    private var tintColor: UIColor { PassColor.aliasInteractionNormMajor2 }

    var body: some View {
        NavigationStack {
            // ZStack instead of VStack because of SwiftUI bug.
            // See more in "CreateAliasLiteView.swift"
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(selection.suffixes, id: \.suffix) { suffix in
                            HStack {
                                Text(suffix.suffix)
                                    .foregroundStyle((isSelected(suffix) ?
                                            tintColor : PassColor.textNorm).toColor)
                                Spacer()

                                if isSelected(suffix) {
                                    Image(uiImage: IconProvider.checkmark)
                                        .foregroundStyle(tintColor.toColor)
                                }
                            }
                            .contentShape(.rect)
                            .background(Color.clear)
                            .padding(.horizontal)
                            .frame(height: OptionRowHeight.compact.value)
                            .onTapGesture {
                                selection.selectedSuffix = suffix
                                onDismiss()
                            }

                            if suffix != selection.suffixes.last {
                                PassDivider()
                                    .padding(.horizontal)
                            }
                        }

                        if showTip {
                            tip
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .animation(.default, value: showTip)
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Suffix")
                        .navigationTitleText()
                }
            }
        }
    }
}

private extension SuffixSelectionView {
    func isSelected(_ suffix: Suffix) -> Bool {
        suffix == selection.selectedSuffix
    }

    var tip: some View {
        TipBanner(configuration: .init(arrowMode: .none,
                                       description: tipDescription,
                                       cta: .init(title: #localized("Add domain"),
                                                  action: onAddDomain)),
                  onDismiss: onDismissTip)
    }

    var tipDescription: LocalizedStringKey {
        "By adding your domain, you can create aliases like hi@my-domain.com."
    }
}
