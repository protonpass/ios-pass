//
// FeatureDiscovery.swift
// Proton Pass - Created on 17/12/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import SwiftUI

// Custom ViewModifier for displaying overlay views
private struct FeatureDiscoveryOverlay<Overlay: View>: ViewModifier {
    @StateObject private var model: FeatureDiscoveryOverlayViewModel
    private let overlay: () -> Overlay
    private let config: FeatureDiscoveryConfig
    private let feature: NewFeature

    init(feature: NewFeature,
         config: FeatureDiscoveryConfig,
         storage: UserDefaults,
         @ViewBuilder overlay: @escaping () -> Overlay) {
        _model = .init(wrappedValue: .init(feature: feature, storage: storage))
        self.overlay = overlay
        self.config = config
        self.feature = feature
    }

    func body(content: Content) -> some View {
        ZStack(alignment: config.alignment) {
            content
                .simultaneousGesture(TapGesture().onEnded {
                    if config.shouldHideAfterAction {
                        model.removeOverlay(feature: feature)
                    }
                })
            // Conditional overlay view
            if !model.shouldOverlayBeInvisible {
                overlay()
                    .offset(config.offset)
            }
        }
    }
}

@MainActor
private final class FeatureDiscoveryOverlayViewModel: ObservableObject {
    @Published private(set) var shouldOverlayBeInvisible = true
    private let storage: UserDefaults

    init(feature: NewFeature,
         storage: UserDefaults) {
        self.storage = storage
        if feature.canDisplay {
            shouldOverlayBeInvisible = storage.bool(forKey: feature.storageKey)
        }
    }

    func removeOverlay(feature: NewFeature) {
        storage.set(true, forKey: feature.storageKey)
        shouldOverlayBeInvisible = true
    }
}

public enum NewFeature: Sendable {
    case itemSharing(canDisplay: Bool)

    var storageKey: String {
        switch self {
        case .itemSharing:
            "itemSharing"
        }
    }

    var canDisplay: Bool {
        switch self {
        case let .itemSharing(canDisplay):
            canDisplay
        }
    }
}

public extension View {
    func featureDiscoveryOverlay(feature: NewFeature,
                                 config: FeatureDiscoveryConfig = .default,
                                 storage: UserDefaults = kSharedUserDefaults,
                                 @ViewBuilder overlay: @escaping () -> some View) -> some View {
        modifier(FeatureDiscoveryOverlay(feature: feature,
                                         config: config,
                                         storage: storage,
                                         overlay: overlay))
    }
}

public struct FeatureDiscoveryConfig {
    public let alignment: Alignment
    public let offset: CGSize
    public let shouldHideAfterAction: Bool

    public init(alignment: Alignment = .topTrailing, offset: CGSize = .zero, shouldHideAfterAction: Bool = true) {
        self.alignment = alignment
        self.offset = offset
        self.shouldHideAfterAction = shouldHideAfterAction
    }

    public static var `default`: FeatureDiscoveryConfig {
        FeatureDiscoveryConfig(alignment: .topTrailing, offset: .zero, shouldHideAfterAction: true)
    }
}
