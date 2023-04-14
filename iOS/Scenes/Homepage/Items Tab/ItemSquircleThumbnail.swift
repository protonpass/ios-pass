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
                    Color(uiColor: PassColor.backgroundMedium)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(width: size.height, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: size.height / 2.5, style: .continuous))
            .animation(.default, value: image)
            .onFirstAppear {
                Task { @MainActor in
                    do {
                        if let data = try await repository.getFavIconData(for: url) {
                            image = .init(data: data)
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}
