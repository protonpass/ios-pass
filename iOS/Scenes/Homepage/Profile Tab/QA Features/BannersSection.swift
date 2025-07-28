//
// BannersSection.swift
// Proton Pass - Created on 27/05/2023.
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

import FactoryKit
import SwiftUI

struct BannersSection: View {
    var body: some View {
        NavigationLink(destination: { ManageBannersView() },
                       label: { Text(verbatim: "Banners") })
    }
}

private struct ManageBannersView: View {
    var body: some View {
        Form {
            InfoBannerView(banner: .invite([.mocked]), dismiss: {}, action: {})
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
