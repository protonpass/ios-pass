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
struct OverlayViewModifier<Overlay: View>: ViewModifier {
    @StateObject private var model: OverlayViewModifierModel
    private let overlay: () -> Overlay
    private let config: FeatureDiscoveryConfig
    private let feature: FeatureDiscoveries

    init(feature: FeatureDiscoveries,
         config: FeatureDiscoveryConfig,
         @ViewBuilder overlay: @escaping () -> Overlay) {
        _model = .init(wrappedValue: .init(feature: feature))
        self.overlay = overlay
        self.config = config
        self.feature = feature
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
                .simultaneousGesture(TapGesture().onEnded {
                    if config.shouldHideAfterAction {
                        model.removeOverlay(feature: feature)
                    }
                })
            // Conditional overlay view
            if model.isOverlayVisible {
                overlay()
                    .offset(config.offset)
            }
        }
    }
}

final class OverlayViewModifierModel: ObservableObject {
    @Published private(set) var isOverlayVisible: Bool = true
    private let storage: UserDefaults

    init(feature: FeatureDiscoveries,
         storage: UserDefaults = kSharedUserDefaults) {
        self.storage = storage
        isOverlayVisible = storage.object(forKey: feature.rawValue) as? Bool ?? true
    }

    func removeOverlay(feature: FeatureDiscoveries) {
        storage.set(false, forKey: feature.rawValue)
        isOverlayVisible = false
    }
}

public enum FeatureDiscoveries: String, Sendable {
    case itemSharing

    // TODO: need to get end display date
    var discoveryEnded: Bool {
        switch self {
        case .itemSharing:
            Date().timeIntervalSinceNow.sign == .minus
        }
    }
}

public extension View {
    func featureDiscoveryOverlay(feature: FeatureDiscoveries,
                                 config: FeatureDiscoveryConfig = .default,
                                 @ViewBuilder overlay: @escaping () -> some View) -> some View {
        modifier(OverlayViewModifier(feature: feature,
                                     config: config,
                                     overlay: overlay))
    }
}

public struct FeatureDiscoveryConfig {
    public let alignment: Alignment
    public let offset: CGSize
    public let shouldHideAfterAction: Bool

    public init(alignment: Alignment, offset: CGSize, shouldHideAfterAction: Bool) {
        self.alignment = alignment
        self.offset = offset
        self.shouldHideAfterAction = shouldHideAfterAction
    }

    public static var `default`: FeatureDiscoveryConfig {
        FeatureDiscoveryConfig(alignment: .topTrailing, offset: .zero, shouldHideAfterAction: false)
    }
}
