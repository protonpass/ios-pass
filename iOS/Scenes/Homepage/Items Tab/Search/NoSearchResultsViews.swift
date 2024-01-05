//
// NoSearchResultsViews.swift
// Proton Pass - Created on 16/03/2023.
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

import DesignSystem
import Macro
import SwiftUI

struct NoSearchResultsInAllVaultView: View {
    let query: String

    var body: some View {
        VStack {
            Text("Couldn't find \"\(query)\"")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: PassColor.textNorm))
                .padding(.bottom)
                .animationsDisabled()

            TrySearchAgainText()
        }
        .padding(.horizontal)
        .padding(.top, 180)
    }
}

struct NoSearchResultsInPreciseVaultView: View {
    let query: String
    let vaultName: String
    let action: () -> Void

    var body: some View {
        VStack {
            Text(#localized("Couldn't find \"%1$@\" in %2$@", query, vaultName))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: PassColor.textNorm))
                .padding(.bottom)
                .animationsDisabled()

            TrySearchAgainText()

            Button(action: action) {
                Label("Search in all vaults", systemImage: "magnifyingglass")
                    .foregroundColor(Color(uiColor: PassColor.interactionNormMajor2))
                    .padding()
                    .background(Color(uiColor: PassColor.interactionNormMinor2))
                    .clipShape(Capsule())
            }
            .padding(.top, 50)
        }
        .padding(.horizontal)
        .padding(.top, 150)
    }
}

struct NoSearchResultsInTrashView: View {
    let query: String

    var body: some View {
        VStack {
            Text("Couldn't find \"\(query)\" in Trash")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(uiColor: PassColor.textNorm))
                .padding(.bottom)
                .animationsDisabled()

            TrySearchAgainText()
        }
        .padding(.horizontal)
        .padding(.top, 180)
    }
}

private struct TrySearchAgainText: View {
    var body: some View {
        Text("Try searching using different spelling or keywords")
            .font(.callout)
            .foregroundColor(Color(uiColor: PassColor.textWeak))
            .multilineTextAlignment(.center)
    }
}
