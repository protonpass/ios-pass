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
import DesignSystem
import SwiftUI

public enum FeatureDiscoveryDisplayMode {
    case overlay(FeatureDiscoveryDisplayConfig)
    case trailing(FeatureDiscoveryDisplayConfig)
}

public enum FeatureDiscoveryBadgeMode {
    case newLabel, dot
}

private struct FeatureDiscoveryOverlay: ViewModifier {
    @StateObject private var viewModel: FeatureDiscoveryOverlayViewModel
    private let displayMode: FeatureDiscoveryDisplayMode
    private let badgeMode: FeatureDiscoveryBadgeMode
    private let feature: NewFeature

    init(feature: NewFeature,
         canDisplay: Bool,
         displayMode: FeatureDiscoveryDisplayMode,
         badgeMode: FeatureDiscoveryBadgeMode,
         storage: UserDefaults) {
        _viewModel = .init(wrappedValue: .init(feature: feature,
                                               canDisplay: canDisplay,
                                               storage: storage))
        self.displayMode = displayMode
        self.badgeMode = badgeMode
        self.feature = feature
    }

    func body(content: Content) -> some View {
        switch displayMode {
        case let .overlay(config):
            ZStack(alignment: config.alignment) {
                content
                    .simultaneousGesture(for: feature,
                                         config: config,
                                         action: viewModel.removeOverlay)

                badge(for: config)
            }

        case let .trailing(config):
            HStack {
                content
                badge(for: config)
            }
            .simultaneousGesture(for: feature,
                                 config: config,
                                 action: viewModel.removeOverlay)
        }
    }

    @ViewBuilder
    private func badge(for config: FeatureDiscoveryDisplayConfig) -> some View {
        if !viewModel.shouldBadgeBeInvisible {
            switch badgeMode {
            case .newLabel:
                Text("NEW", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(PassColor.textInvert.toColor)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PassColor.signalInfo.toColor)
                    .cornerRadius(6)
                    .offset(config.offset)

            case .dot:
                Circle()
                    .fill(PassColor.signalInfo.toColor)
                    .frame(width: 10, height: 10)
                    .offset(config.offset)
            }
        }
    }
}

private extension View {
    func simultaneousGesture(for feature: NewFeature,
                             config: FeatureDiscoveryDisplayConfig,
                             action: @escaping (NewFeature) -> Void) -> some View {
        simultaneousGesture(TapGesture().onEnded {
            if config.shouldHideAfterAction {
                action(feature)
            }
        })
    }
}

@MainActor
private final class FeatureDiscoveryOverlayViewModel: ObservableObject {
    @Published private(set) var shouldBadgeBeInvisible = true
    private let storage: UserDefaults

    init(feature: NewFeature,
         canDisplay: Bool,
         storage: UserDefaults) {
        self.storage = storage
        if canDisplay {
            shouldBadgeBeInvisible = storage.bool(forKey: feature.rawValue)
        }
    }

    func removeOverlay(_ feature: NewFeature) {
        storage.set(true, forKey: feature.rawValue)
        shouldBadgeBeInvisible = true
    }
}

public enum NewFeature: String, Sendable {
    case customItems
}

public extension View {
    func featureDiscoveryOverlay(feature: NewFeature,
                                 canDisplay: Bool,
                                 displayMode: FeatureDiscoveryDisplayMode,
                                 badgeMode: FeatureDiscoveryBadgeMode,
                                 storage: UserDefaults = kSharedUserDefaults) -> some View {
        modifier(FeatureDiscoveryOverlay(feature: feature,
                                         canDisplay: canDisplay,
                                         displayMode: displayMode,
                                         badgeMode: badgeMode,
                                         storage: storage))
    }
}

public struct FeatureDiscoveryDisplayConfig {
    public let alignment: Alignment
    public let offset: CGSize
    public let shouldHideAfterAction: Bool

    public init(alignment: Alignment,
                offset: CGSize,
                shouldHideAfterAction: Bool) {
        self.alignment = alignment
        self.offset = offset
        self.shouldHideAfterAction = shouldHideAfterAction
    }

    public static var defaultOverlay: FeatureDiscoveryDisplayConfig {
        .init(alignment: .topTrailing, offset: .zero, shouldHideAfterAction: true)
    }

    public static var defaultTrailing: FeatureDiscoveryDisplayConfig {
        .init(alignment: .leading, offset: .zero, shouldHideAfterAction: true)
    }
}
