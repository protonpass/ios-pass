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

import Core
import Factory
import SwiftUI

struct BannersSection: View {
    var body: some View {
        NavigationLink(destination: { ManageBannersView() },
                       label: { Text(verbatim: "Banners") })
    }
}

private struct ManageBannersView: View {
    @StateObject private var preferences = resolve(\SharedToolingContainer.preferences)

    var body: some View {
        Form {
            Section {
                Text(verbatim: "In order for changes to take effect, either move app to background or close app")
                Button(action: {
                    preferences.dismissedBannerIds.removeAll()
                }, label: {
                    Text(verbatim: "Undismiss all banners")
                })
            }

            ForEach(InfoBanner.allCases, id: \.id) { banner in
                VStack {
                    InfoBannerView(banner: banner, dismiss: {}, action: {})

                    let binding = Binding<Bool>(get: {
                        preferences.dismissedBannerIds.contains(banner.id)
                    }, set: { newValue in
                        if newValue {
                            preferences.dismissedBannerIds.append(banner.id)
                        } else {
                            preferences.dismissedBannerIds.removeAll(where: { $0 == banner.id })
                        }
                    })

                    Toggle(isOn: binding) {
                        Text(verbatim: "Dismissed")
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
