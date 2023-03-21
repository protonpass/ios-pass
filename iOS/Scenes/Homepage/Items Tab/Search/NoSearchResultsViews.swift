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

import SwiftUI
import UIComponents

struct NoSearchResultsInAllVaultView: View {
    let query: String

    var body: some View {
        VStack {
            Text("Coundn't find \"\(query)\" in all vaults")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
                .animationsDisabled()

            Text("Try search again using different spelling or keyword")
                .font(.callout)
                .foregroundColor(.textWeak)
                .multilineTextAlignment(.center)
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
            Text("Coundn't find \"\(query)\" in \(vaultName)")
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.bottom)
                .animationsDisabled()

            Text("Try search again using different spelling or keyword")
                .font(.callout)
                .foregroundColor(.textWeak)
                .multilineTextAlignment(.center)

            Button(action: action) {
                Label("Search in all vaults", systemImage: "magnifyingglass")
                    .foregroundColor(.passBrand)
                    .padding()
                    .background(Color.passBrand.opacity(0.08))
                    .clipShape(Capsule())
            }
            .padding(.top, 50)
        }
        .padding(.horizontal)
        .padding(.top, 180)
    }
}
