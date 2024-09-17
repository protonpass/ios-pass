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

public struct NoSearchResultsInAllVaultView: View {
    let query: String

    public init(query: String) {
        self.query = query
    }

    public var body: some View {
        VStack {
            Spacer()
                .frame(maxHeight: 180)
            Text("Couldn't find \"\(query)\"", bundle: .module)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.bottom)
                .animationsDisabled()
            TrySearchAgainText()
        }
        .padding(.horizontal)
    }
}

public struct NoSearchResultsInPreciseVaultView: View {
    let query: String
    let vaultName: String
    let action: () -> Void

    public init(query: String, vaultName: String, action: @escaping () -> Void) {
        self.query = query
        self.vaultName = vaultName
        self.action = action
    }

    public var body: some View {
        VStack {
            Text(#localized("Couldn't find \"%1$@\" in %2$@", bundle: .module, query, vaultName))
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.bottom)
                .animationsDisabled()

            TrySearchAgainText()

            Button(action: action) {
                Label(#localized("Search in all vaults", bundle: .module), systemImage: "magnifyingglass")
                    .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                    .padding()
                    .background(PassColor.interactionNormMinor2.toColor)
                    .clipShape(Capsule())
            }
            .padding(.top, 50)
        }
        .padding(.horizontal)
        .padding(.top, 150)
    }
}

public struct NoSearchResultsInTrashView: View {
    let query: String

    public init(query: String) {
        self.query = query
    }

    public var body: some View {
        VStack {
            Text("Couldn't find \"\(query)\" in Trash", bundle: .module)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm.toColor)
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
        Text("Try searching using different spelling or keywords", bundle: .module)
            .font(.callout)
            .foregroundStyle(PassColor.textWeak.toColor)
            .multilineTextAlignment(.center)
    }
}
