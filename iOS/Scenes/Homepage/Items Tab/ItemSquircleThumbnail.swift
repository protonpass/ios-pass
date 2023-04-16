//
// ItemSquircleThumbnail.swift
// Proton Pass - Created on 14/04/2023.
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
import SwiftUI
import UIComponents

enum ItemSquircleThumbnailSize {
    case regular, large

    var height: CGFloat {
        switch self {
        case .regular:
            return 40
        case .large:
            return 60
        }
    }

    var strokeWidth: CGFloat {
        switch self {
        case .regular:
            return 2
        case .large:
            return 3
        }
    }
}

struct ItemSquircleThumbnail: View {
    @State private var image: UIImage?

    let data: ItemThumbnailData
    let repository: FavIconRepositoryProtocol
    var size: ItemSquircleThumbnailSize = .regular

    var body: some View {
        switch data {
        case .icon(let type):
            SquircleThumbnail(data: .icon(type.icon),
                              tintColor: type.normMajor1Color,
                              backgroundColor: type.normMinor1Color,
                              height: size.height)

        case let .initials(type, initials):
            SquircleThumbnail(data: .initials(initials),
                              tintColor: type.normMajor1Color,
                              backgroundColor: type.normMinor1Color,
                              height: size.height)

        case let .favIcon(type, url, initials):
            ZStack {
                SquircleThumbnail(data: .initials(initials),
                                  tintColor: type.normMajor1Color,
                                  backgroundColor: type.normMinor1Color,
                                  height: size.height)

                if let image {
                    Color(uiColor: PassColor.backgroundWeak)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(size.height / 5)
                }
            }
            .frame(width: size.height, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: size.height / 2.5, style: .continuous))
            .overlay(overlay)
            .animation(.default, value: image)
            .onFirstAppear {
                Task { @MainActor in
                    do {
                        let favIcon = try await repository.getIcon(for: url)
                        if !favIcon.data.isEmpty {
                            self.image = .init(data: favIcon.data)
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var overlay: some View {
        if image != nil {
            RoundedRectangle(cornerRadius: size.height / 2.5, style: .continuous)
                .strokeBorder(Color(uiColor: PassColor.backgroundMedium),
                              lineWidth: size.strokeWidth)
        } else {
            EmptyView()
        }
    }
}
