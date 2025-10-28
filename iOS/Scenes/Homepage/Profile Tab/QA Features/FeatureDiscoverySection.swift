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

@_spi(QA)
import Client
import DesignSystem
import FactoryKit
import SwiftUI

struct FeatureDiscoverySection: View {
    var body: some View {
        NavigationLink(destination: { FeatureDiscoveryView() },
                       label: { Text(verbatim: "Feature Discovery") })
    }
}

private extension NewFeature {
    var description: String {
        switch self {
        case .customItems:
            "Hide custom items discovery"
        }
    }
}

struct FeatureDiscoveryView: View {
    @State private var eligibleDiscoveries = Set<NewFeature>()
    private let manager = resolve(\SharedServiceContainer.featureDiscoveryManager)

    var body: some View {
        Form {
            if NewFeature.allCases.isEmpty {
                Text(verbatim: "No new features")
                    .foregroundStyle(PassColor.textWeak)
            } else {
                content
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(manager.eligibleDiscoveries) { discoveries in
            eligibleDiscoveries = discoveries
        }
    }
}

private extension FeatureDiscoveryView {
    var content: some View {
        Section {
            ForEach(NewFeature.allCases, id: \.self) { feature in
                StaticToggle(.verbatim(feature.description),
                             isOn: !eligibleDiscoveries.contains(feature),
                             action: {
                                 if eligibleDiscoveries.contains(feature) {
                                     manager.dismissDiscovery(for: feature)
                                 } else {
                                     manager.undismissDiscovery(for: feature)
                                 }
                             })
            }
        } header: {
            Text(verbatim: "Reset feature discovery")
        }
    }
}
