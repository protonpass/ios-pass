//
// FeatureDiscoverySection.swift
// Proton Pass - Created on 24/01/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import FactoryKit
import Observation
import Screens
import SwiftUI

@available(iOS 17, *)
struct FeatureDiscoverySection: View {
    var body: some View {
        NavigationLink(destination: { FeatureDiscoveryView() },
                       label: { Text(verbatim: "Feature Discovery") })
    }
}

@available(iOS 17, *)
struct FeatureDiscoveryView: View {
    @State private var viewModel = FeatureDiscoverySectionViewModel()

    var body: some View {
        Form {
            Section {
                StaticToggle(.verbatim("Hide new custom items feature"),
                             isOn: viewModel.hideCustomItems,
                             action: { viewModel.toggle(feature: .customItems) })
            } header: {
                Text(verbatim: "Reset feature discovery")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17, *)
@MainActor
@Observable
private final class FeatureDiscoverySectionViewModel {
    private(set) var hideCustomItems = false

    @ObservationIgnored
    private let storage: UserDefaults

    init(storage: UserDefaults = kSharedUserDefaults) {
        self.storage = storage
        refresh()
    }

    private func refresh() {
        hideCustomItems = storage.bool(forKey: NewFeature.customItems.rawValue)
    }

    func toggle(feature: NewFeature) {
        storage.set(false, forKey: feature.rawValue)
        refresh()
    }
}
