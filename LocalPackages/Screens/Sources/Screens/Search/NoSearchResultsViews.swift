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

public struct NoSearchResultsView: View {
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

private struct TrySearchAgainText: View {
    var body: some View {
        Text("Try searching using different spelling or keywords", bundle: .module)
            .font(.callout)
            .foregroundStyle(PassColor.textWeak.toColor)
            .multilineTextAlignment(.center)
    }
}
