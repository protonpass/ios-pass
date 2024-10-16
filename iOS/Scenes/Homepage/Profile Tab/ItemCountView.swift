//
// ItemCountView.swift
// Proton Pass - Created on 30/03/2023.
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

import Client
import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import SwiftUI

private let kChipHeight: CGFloat = 56

struct ItemCountView: View {
    @StateObject private var vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    let plan: Plan?
    let onSelectItemType: (ItemContentType) -> Void
    let onSelectLoginsWith2fa: () -> Void

    var body: some View {
        switch vaultsManager.state {
        case .loading:
            skeleton
        case let .loaded(vaults, trashedItems):
            let activeItems = vaults.map(\.items).reduce(into: []) { $0 += $1 }
            let allItems = activeItems + trashedItems
            let itemCount = ItemCount(items: allItems)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    CounterChip(configuration: ItemContentType.login.toConfiguration,
                                value: itemCount.login,
                                onSelect: { onSelectItemType(.login) })
                    CounterChip(configuration: ItemContentType.alias.toConfiguration,
                                value: itemCount.alias,
                                maxValue: plan?.aliasLimit,
                                onSelect: { onSelectItemType(.alias) })
                    CounterChip(configuration: ItemContentType.creditCard.toConfiguration,
                                value: itemCount.creditCard,
                                onSelect: { onSelectItemType(.creditCard) })
                    CounterChip(configuration: ItemContentType.note.toConfiguration,
                                value: itemCount.note,
                                onSelect: { onSelectItemType(.note) })
                    CounterChip(configuration: ItemContentType.identity.toConfiguration,
                                value: itemCount.identity,
                                onSelect: { onSelectItemType(.identity) })
                    CounterChip(configuration: .init(icon: IconProvider.lock,
                                                     iconTint: PassColor.passwordInteractionNorm,
                                                     iconBackground: PassColor.passwordInteractionNormMinor1),
                                value: itemCount.loginWith2fa,
                                onSelect: { onSelectLoginsWith2fa() })
                }
                .padding(.horizontal)
            }
        case let .error(error):
            Text(error.localizedDescription)
                .foregroundStyle(PassColor.signalDanger.toColor)
        }
    }

    private var skeleton: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(0...5, id: \.self) { _ in
                    SkeletonBlock()
                        .frame(width: 100, height: kChipHeight)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .shimmering()
        }
        .scrollDisabled(true)
    }
}

private struct CounterChip: View {
    let configuration: Configuration
    let value: Int
    var maxValue: Int?
    let onSelect: () -> Void

    struct Configuration {
        let icon: UIImage
        let iconTint: UIColor
        let iconBackground: UIColor
    }

    var body: some View {
        HStack {
            CircleButton(icon: configuration.icon,
                         iconColor: configuration.iconTint,
                         backgroundColor: configuration.iconBackground,
                         type: .small)

            Spacer()

            if let maxValue {
                Text(verbatim: "\(value)")
                    .fontWeight(.bold)
                    .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                    Text(verbatim: "/\(maxValue)")
                    .fontWeight(.bold)
                    .adaptiveForegroundStyle(PassColor.textWeak.toColor)
            } else {
                Text(verbatim: "\(value)")
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }

            Spacer()
        }
        .padding(10)
        .frame(height: kChipHeight)
        .frame(minWidth: 103)
        .overlay(Capsule().strokeBorder(PassColor.inputBorderNorm.toColor, lineWidth: 1))
        .contentShape(.rect)
        .onTapGesture {
            if value > 0 {
                onSelect()
            }
        }
    }
}

private extension ItemContentType {
    var toConfiguration: CounterChip.Configuration {
        .init(icon: regularIcon, iconTint: normColor, iconBackground: normMinor1Color)
    }
}
