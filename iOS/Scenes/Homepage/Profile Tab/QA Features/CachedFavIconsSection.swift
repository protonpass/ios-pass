//
// CachedFavIconsSection.swift
// Proton Pass - Created on 16/04/2023.
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
import Factory
import SwiftUI

struct CachedFavIconsSection: View {
    var body: some View {
        NavigationLink(destination: { CachedFavIconsView() },
                       label: { Text(verbatim: "Cached fav icons") })
    }
}

@MainActor
final class CachedFavIconsViewModel: ObservableObject {
    @Published private(set) var icons = [FavIcon]()
    @Published private(set) var error: (any Error)?

    private let favIconRepository = resolve(\SharedRepositoryContainer.favIconRepository)

    init() {}

    func loadIcons() {
        Task { [weak self] in
            guard let self else { return }
            do {
                error = nil
                icons = try await favIconRepository.getAllCachedIcons()
            } catch {
                self.error = error
            }
        }
    }

    func emptyCache() {
        Task { [weak self] in
            guard let self else { return }
            do {
                error = nil
                try await favIconRepository.emptyCache()
                icons = try await favIconRepository.getAllCachedIcons()
            } catch {
                self.error = error
            }
        }
    }
}

struct CachedFavIconsView: View {
    @StateObject private var viewModel = CachedFavIconsViewModel()
    var body: some View {
        Form {
            if let error = viewModel.error {
                RetryableErrorView(error: error, onRetry: viewModel.loadIcons)
            } else {
                if viewModel.icons.isEmpty {
                    Text(verbatim: "Empty cache")
                        .font(.body.italic())
                        .foregroundStyle(.secondary)
                } else {
                    cachedIcons
                }
            }
        }
        .navigationTitle(Text(verbatim: "Cached fav icons"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.emptyCache() } label: {
                    Label(title: {
                        Text(verbatim: "Empty cache")
                    }, icon: {
                        Image(systemName: "trash")
                    })
                }
            }
        }
        .onFirstAppear(perform: viewModel.loadIcons)
    }

    @ViewBuilder
    private var cachedIcons: some View {
        Section {
            Text(verbatim: "🔴 icon is cached but can't be displayed")
            Text(verbatim: "🟡 icon doesn't exist")
        }

        Section(content: {
            ForEach(viewModel.icons, id: \.hashValue) { icon in
                HStack {
                    if icon.data.isEmpty {
                        Color.yellow
                            .clipShape(Circle())
                            .frame(width: 24, height: 24)
                    } else {
                        if let image = UIImage(data: icon.data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            Color.red
                                .clipShape(Circle())
                                .frame(width: 24, height: 24)
                        }
                    }

                    Text(icon.domain)
                }
            }
        }, header: {
            Text(verbatim: "\(viewModel.icons.count) cached icons")
        })
    }
}
