//
// GenericItemView.swift
// Proton Pass - Created on 07/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_UIFoundations
import SwiftUI

public enum GenericItemDetail {
    /// When detail has value
    case value(String)
    /// Optional placeholder when detail has no value
    case placeholder(String?)
}

extension GenericItemDetail: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .value(let value):
            hasher.combine(value)
        case .placeholder(let value):
            hasher.combine(value)
        }
    }
}

public protocol GenericItemProtocol {
    var icon: UIImage { get }
    var iconTintColor: UIColor { get }
    var title: String { get }
    var detail: GenericItemDetail { get }
}

public struct GenericItemView<TrailingView: View>: View {
    private let item: GenericItemProtocol
    private let action: () -> Void
    private let subtitleLineLimit: Int?
    private let trailingView: TrailingView

    public init(item: GenericItemProtocol,
                action: @escaping () -> Void,
                subtitleLineLimit: Int? = nil,
                @ViewBuilder trailingView: () -> TrailingView = { EmptyView() }) {
        self.item = item
        self.action = action
        self.subtitleLineLimit = subtitleLineLimit
        self.trailingView = trailingView()
    }

    public var body: some View {
        HStack {
            Button(action: action) {
                HStack(spacing: 16) {
                    ZStack {
                        Color(item.iconTintColor).opacity(0.1)
                        Image(uiImage: item.icon)
                            .resizable()
                            .foregroundColor(Color(item.iconTintColor))
                            .padding(7.5)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .foregroundColor(.textNorm)

                        switch item.detail {
                        case .value(let detail):
                            if !detail.isEmpty {
                                Text(detail)
                                    .font(.callout)
                                    .foregroundColor(.textWeak)
                                    .lineLimit(subtitleLineLimit)
                            }

                        case .placeholder(let placeholder):
                            if let placeholder, !placeholder.isEmpty {
                                Text(placeholder)
                                    .font(.callout.italic())
                                    .foregroundColor(.textWeak)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            trailingView
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
}
