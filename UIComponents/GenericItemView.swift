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

public protocol GenericItemProtocol {
    var icon: UIImage { get }
    var title: String { get }
    var detail: String? { get }
}

public struct GenericItem: GenericItemProtocol {
    public let icon: UIImage
    public let title: String
    public var detail: String?

    public init(icon: UIImage, title: String, detail: String? = nil) {
        self.icon = icon
        self.title = title
        self.detail = detail
    }
}

public struct GenericItemView<TrailingView: View>: View {
    private let item: GenericItemProtocol
    private let action: () -> Void
    private let subtitleLineLimit: Int?
    private let trailingView: TrailingView

    public init(item: GenericItemProtocol,
                action: @escaping () -> Void,
                subtitleLineLimit: Int? = 1,
                @ViewBuilder trailingView: () -> TrailingView) {
        self.item = item
        self.action = action
        self.subtitleLineLimit = subtitleLineLimit
        self.trailingView = trailingView()
    }

    public var body: some View {
        VStack {
            HStack {
                Button(action: action) {
                    HStack {
                        VStack {
                            Image(uiImage: item.icon)
                                .foregroundColor(Color(.label))
                                .padding(.top, -20)
                            EmptyView()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                            if let detail = item.detail {
                                Text(detail)
                                    .font(.callout)
                                    .foregroundColor(Color(.secondaryLabel))
                                    .lineLimit(subtitleLineLimit)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                trailingView
                    .padding(.trailing)
            }
        }
    }
}
