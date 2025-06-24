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

import DesignSystem
import SwiftUI

public enum FeatureDiscoveryDisplayMode {
    case overlay(FeatureDiscoveryDisplayConfig)
    case trailing(FeatureDiscoveryDisplayConfig)
}

private struct FeatureDiscoveryModifier: ViewModifier {
    private let mode: FeatureDiscoveryDisplayMode

    init(mode: FeatureDiscoveryDisplayMode) {
        self.mode = mode
    }

    func body(content: Content) -> some View {
        switch mode {
        case let .overlay(config):
            ZStack(alignment: config.alignment) {
                content
                    .simultaneousGesture(config: config)

                badge(for: config)
            }

        case let .trailing(config):
            HStack {
                content
                badge(for: config)
            }
            .simultaneousGesture(config: config)
        }
    }

    @ViewBuilder
    private func badge(for config: FeatureDiscoveryDisplayConfig) -> some View {
        switch config.badgeMode {
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

private extension View {
    func simultaneousGesture(config: FeatureDiscoveryDisplayConfig) -> some View {
        simultaneousGesture(TapGesture().onEnded {
            config.action?()
        })
    }
}

public extension View {
    func featureDiscovery(mode: FeatureDiscoveryDisplayMode) -> some View {
        modifier(FeatureDiscoveryModifier(mode: mode))
    }
}

public struct FeatureDiscoveryDisplayConfig {
    public let alignment: Alignment
    public let offset: CGSize
    public let badgeMode: BadgeMode
    public let action: (() -> Void)?

    public enum BadgeMode {
        case newLabel, dot
    }

    public init(alignment: Alignment,
                offset: CGSize = .zero,
                badgeMode: BadgeMode,
                action: (() -> Void)? = nil) {
        self.alignment = alignment
        self.offset = offset
        self.badgeMode = badgeMode
        self.action = action
    }
}
