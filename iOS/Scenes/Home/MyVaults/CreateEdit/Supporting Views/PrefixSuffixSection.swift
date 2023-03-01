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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

enum PrefixUtils {
    static func generatePrefix(fromTitle title: String) -> String {
        var lowercasedTitle = title.lowercased()
        let allowedCharacters = AliasPrefixValidator.allowedCharacters
        lowercasedTitle.unicodeScalars.removeAll(where: { !allowedCharacters.contains($0) })
        return String(lowercasedTitle.prefix(40))
    }
}

struct PrefixSuffixSection: View {
    @Binding var prefix: String
    @Binding var prefixManuallyEdited: Bool
    @FocusState var isFocusedOnPrefix: Bool
    let suffixSelection: SuffixSelection
    let prefixError: AliasPrefixError?
    var onSubmit: ((() -> Void))?

    var body: some View {
        VStack(alignment: .leading, spacing: kItemDetailSectionPadding) {
            prefixRow
            Divider()
            suffixRow
        }
        .padding(.vertical, kItemDetailSectionPadding)
        .roundedEditableSection()
    }

    private var prefixRow: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Prefix")
                        .sectionTitleText()
                    TextField("Add a prefix", text: $prefix) { _ in
                        prefixManuallyEdited = true
                    }
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .focused($isFocusedOnPrefix)
                    .submitLabel(.done)
                    .onSubmit { onSubmit?() }
                    if let prefixError {
                        Text(prefixError.localizedDescription)
                            .font(.callout)
                            .foregroundColor(.notificationError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.default, value: prefixError)

                if !prefix.isEmpty {
                    Button(action: {
                        prefix = ""
                    }, label: {
                        ItemDetailSectionIcon(icon: IconProvider.cross, color: .textWeak)
                    })
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, kItemDetailSectionPadding)
        .animation(.default, value: prefix.isEmpty)
    }

    @ViewBuilder
    private var suffixRow: some View {
        Menu(content: {
            ForEach(suffixSelection.suffixes, id: \.suffix) { suffix in
                Button(action: {
                    suffixSelection.selectedSuffix = suffix
                }, label: {
                    Label(title: {
                        Text(suffix.suffix)
                    }, icon: {
                        if suffix.suffix == suffixSelection.selectedSuffix?.suffix {
                            Image(systemName: "checkmark")
                        }
                    })
                })
            }
        }, label: {
            HStack {
                VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                    Text("Suffix")
                        .sectionTitleText()
                    Text(suffixSelection.selectedSuffixString)
                        .sectionContentText()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                ItemDetailSectionIcon(icon: IconProvider.chevronDown, color: .textWeak)
            }
            .padding(.horizontal, kItemDetailSectionPadding)
            .transaction { transaction in
                transaction.animation = nil
            }
        })
    }
}
