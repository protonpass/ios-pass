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
    case small, regular, large

    var height: CGFloat {
        switch self {
        case .small:
            24
        case .regular:
            40
        case .large:
            60
        }
    }

    var pinHeight: CGFloat {
        height / 2
    }

    var strokeWidth: CGFloat {
        switch self {
        case .small:
            1
        case .regular:
            2
        case .large:
            3
        }
    }
}

@MainActor
struct ItemSquircleThumbnail: View {
    @State private var image: UIImage?

    private let repository = resolve(\SharedRepositoryContainer.favIconRepository)
    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let cachedFavIconsManager = resolve(\SharedServiceContainer.cachedFavIconsManager)
    private let data: ItemThumbnailData
    private let pinned: Bool
    private let isEnabled: Bool
    private let size: ItemSquircleThumbnailSize
    private let alternativeBackground: Bool

    init(data: ItemThumbnailData,
         isEnabled: Bool = true,
         pinned: Bool = false,
         size: ItemSquircleThumbnailSize = .regular,
         alternativeBackground: Bool = false) {
        self.data = data
        self.pinned = pinned
        self.isEnabled = isEnabled
        self.size = size
        self.alternativeBackground = alternativeBackground
        if case let .favIcon(_, url, _) = data {
            _image = .init(initialValue: cachedFavIconsManager.get(for: url))
        }
    }

    var body: some View {
        thumbnail
            .overlay(pinned ? pin : nil)
            .animation(.default, value: pinned)
    }
}

private extension ItemSquircleThumbnail {
    @ViewBuilder
    var thumbnail: some View {
        switch data {
        case let .icon(type):
            SquircleThumbnail(data: iconData(type: type),
                              tintColor: type.normMajor2Color,
                              backgroundColor: !isEnabled ? .clear : alternativeBackground ? type
                                  .normMinor2Color : type.normMinor1Color,
                              height: size.height)
                .if(!isEnabled) { view in
                    view.overlay {
                        RoundedRectangle(cornerRadius: size.height / 2.5, style: .continuous)
                            .stroke((alternativeBackground ? type.normMinor2Color : type.normMinor1Color).toColor,
                                    lineWidth: 1)
                    }
                }

        case let .initials(type, initials):
            SquircleThumbnail(data: .initials(initials),
                              tintColor: type.normMajor2Color,
                              backgroundColor: alternativeBackground ? type.normMinor2Color : type.normMinor1Color,
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
                            .stroke(PassColor.inputBorderNorm.toColor, lineWidth: size.strokeWidth)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: size.height / 2.5, style: .continuous))
                } else {
                    SquircleThumbnail(data: .initials(initials),
                                      tintColor: type.normMajor2Color,
                                      backgroundColor: alternativeBackground ? type.normMinor2Color : type
                                          .normMinor1Color,
                                      height: size.height)
                }
            }
            .frame(width: size.height, height: size.height)
            .animation(.default, value: image)
            .onReceive(preferencesManager
                .sharedPreferencesUpdates
                .filter(\.displayFavIcons)
                .receive(on: DispatchQueue.main)) { displayFavIcons in
                    if !displayFavIcons {
                        image = nil
                    }
            }
            .task {
                do {
                    if preferencesManager.sharedPreferences.unwrapped().displayFavIcons,
                       image == nil,
                       let favIcon = try await repository.getIcon(for: url),
                       let newImage = UIImage(data: favIcon.data) {
                        image = newImage
                        cachedFavIconsManager.cache(url: url, image: newImage)
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

private extension ItemSquircleThumbnail {
    var pin: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
            PassColor.backgroundNorm.toColor
                .frame(width: size.pinHeight, height: size.pinHeight)
                .clipShape(Circle())
                .overlay {
                    PinCircleView(tintColor: data.itemContentType.normMajor1Color,
                                  height: size.pinHeight * 4 / 5)
                }
                .padding(-size.pinHeight / 5)
        }
    }

    // swiftlint:disable void_function_in_ternary
    func iconData(type: ItemContentType) -> SquircleThumbnailData {
        if type != .alias {
            size == .regular ? .icon(type.regularIcon) : .icon(type.largeIcon)
        } else {
            isEnabled ? .icon(type.regularIcon) : .icon(PassIcon.aliasSlash)
        }
    }
    // swiftlint:enable void_function_in_ternary
}
