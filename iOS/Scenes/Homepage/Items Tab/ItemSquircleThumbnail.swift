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
import DesignSystem
import Entities
import Factory
import SwiftUI

enum ItemSquircleThumbnailSize {
    case regular, large

    var height: CGFloat {
        switch self {
        case .regular:
            40
        case .large:
            60
        }
    }

    var strokeWidth: CGFloat {
        switch self {
        case .regular:
            2
        case .large:
            3
        }
    }
}

struct ItemSquircleThumbnail: View, Sendable {
    @State private var image: UIImage?

    private let repository = resolve(\SharedRepositoryContainer.favIconRepository)
    private let data: ItemThumbnailData
    private let size: ItemSquircleThumbnailSize

    init(data: ItemThumbnailData, size: ItemSquircleThumbnailSize = .regular) {
        self.data = data
        self.size = size
    }

    var body: some View {
        switch data {
        case let .icon(type):
            SquircleThumbnail(data: size == .regular ? .icon(type.regularIcon) : .icon(type.largeIcon),
                              tintColor: type.normMajor2Color,
                              backgroundColor: type.normMinor1Color,
                              height: size.height)

        case let .initials(type, initials):
            SquircleThumbnail(data: .initials(initials),
                              tintColor: type.normMajor2Color,
                              backgroundColor: type.normMinor1Color,
                              height: size.height)

        case let .favIcon(type, url, initials):
            ZStack {
                if let image {
                    ZStack {
                        Color.white
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(size.height / 5)
                        RoundedRectangle(cornerRadius: size.height / 2.5, style: .continuous)
                            .stroke(Color(uiColor: PassColor.inputBorderNorm), lineWidth: size.strokeWidth)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: size.height / 2.5, style: .continuous))
                } else {
                    SquircleThumbnail(data: .initials(initials),
                                      tintColor: type.normMajor2Color,
                                      backgroundColor: type.normMinor1Color,
                                      height: size.height)
                }
            }
            .frame(width: size.height, height: size.height)
            .animation(.default, value: image)
            .onChange(of: data, perform: { newValue in
                if let newUrl = newValue.url {
                    loadFavIcon(url: newUrl, force: true)
                }
            })
            .onChange(of: repository.settings.shouldDisplayFavIcons) { newValue in
                if newValue {
                    if image == nil {
                        loadFavIcon(url: url, force: false)
                    }
                } else {
                    image = nil
                }
            }
            .onFirstAppear { loadFavIcon(url: url, force: false) }
        }
    }

    private func loadFavIcon(url: String, force: Bool) {
        if !force, image != nil {
            return
        }

        if force {
            image = nil
        }

        Task {
            do {
                if let favIcon = try await repository.getIcon(for: url),
                   let image = UIImage(data: favIcon.data) {
                    await MainActor.run {
                        self.image = image
                    }
                }
            } catch {
                print(error)
            }
        }
    }
}
