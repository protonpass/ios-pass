//
// PrefixSuffixSection.swift
// Proton Pass - Created on 17/02/2023.
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

import Core
import DesignSystem
import Entities
import ProtonCoreUIFoundations
import Screens
import SwiftUI

enum PrefixUtils {
    static func generatePrefix(fromTitle title: String) -> String {
        var lowercasedTitle = title.lowercased()
        let allowedCharacters = Constants.Utils.prefixAllowedCharacters
        lowercasedTitle.unicodeScalars.removeAll(where: { !allowedCharacters.contains($0) })
        return String(lowercasedTitle.prefix(40))
    }
}

struct PrefixSuffixSection<Field: Hashable>: View {
    @Binding var prefix: String
    @Binding var prefixManuallyEdited: Bool
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    let isLoading: Bool
    let tintColor: Color
    let suffixSelection: SuffixSelection
    let prefixError: AliasPrefixError?
    var onSubmitPrefix: (() -> Void)?
    var onSelectSuffix: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding) {
            prefixRow
            PassSectionDivider()
            suffixRow
        }
        .padding(.vertical, DesignConstant.sectionPadding)
        .roundedEditableSection()
        .accentColor(PassColor.interactionNorm)
        .tint(PassColor.interactionNorm)
    }

    private var prefixRow: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Prefix")
                        .editableSectionTitleText(for: prefix)
                    TextField("Add a prefix", text: $prefix) { _ in
                        prefixManuallyEdited = true
                    }
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .focused(focusedField, equals: field)
                    .foregroundStyle(PassColor.textNorm)
                    .submitLabel(.done)
                    .onSubmit { onSubmitPrefix?() }
                    if let prefixError {
                        Text(prefixError.localizedDescription)
                            .font(.callout)
                            .foregroundStyle(PassColor.signalDanger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.default, value: prefixError)

                ClearTextButton(text: $prefix)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animation(.default, value: prefix.isEmpty)
    }

    @ViewBuilder
    private var suffixRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Suffix")
                    .sectionTitleText()

                if isLoading {
                    ZStack {
                        // Dummy text to make ZStack occupy a correct height
                        Text(verbatim: "Dummy text")
                            .opacity(0)
                        SkeletonBlock(tintColor: tintColor)
                            .clipShape(Capsule())
                            .shimmering()
                    }
                } else {
                    Text(suffixSelection.selectedSuffixString)
                        .sectionContentText()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            ItemDetailSectionIcon(icon: IconProvider.chevronDown)
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .animationsDisabled()
        .contentShape(.rect)
        .onTapGesture(perform: onSelectSuffix)
    }
}
