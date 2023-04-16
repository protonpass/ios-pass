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
import SwiftUI
import UIComponents

struct CachedFavIconsSection: View {
    let favIconRepository: FavIconRepositoryProtocol

    var body: some View {
        Section {
            NavigationLink(destination: {
                let viewModel = CachedFavIconsViewModel(favIconRepository: favIconRepository)
                CachedFavIconsView(viewModel: viewModel)
            }, label: {
                Text("Cached fav icons")
            })
        }
    }
}

final class CachedFavIconsViewModel: ObservableObject {
    @Published private(set) var data = [FavIconData]()
    @Published private(set) var error: Error?

    let favIconRepository: FavIconRepositoryProtocol

    init(favIconRepository: FavIconRepositoryProtocol) {
        self.favIconRepository = favIconRepository
    }

    func loadIcons() {
        Task { @MainActor in
            do {
                self.error = nil
                self.data = try favIconRepository.getAllCachedIcons()
            } catch {
                self.error = error
            }
        }
    }

    func emptyCache() {
        Task { @MainActor in
            do {
                self.error = nil
                try favIconRepository.emptyCache()
                self.data = try favIconRepository.getAllCachedIcons()
            } catch {
                self.error = error
            }
        }
    }
}

struct CachedFavIconsView: View {
    @StateObject var viewModel: CachedFavIconsViewModel
    var body: some View {
        Form {
            if let error = viewModel.error {
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: viewModel.loadIcons)
            } else {
                if viewModel.data.isEmpty {
                    Text("Empty cache")
                        .font(.body.italic())
                        .foregroundColor(.secondary)
                } else {
                    cachedIcons
                }
            }
        }
        .navigationTitle("Cached fav icons")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.emptyCache) {
                    Label("Empty cache", systemImage: "trash")
                }
            }
        }
        .onFirstAppear(perform: viewModel.loadIcons)
    }

    @ViewBuilder
    private var cachedIcons: some View {
        Section {
            Text("⚠️ the fav icon is cached but can't be displayed")
            Text("🟠 the fav icon doesn't exist")
        }

        Section(content: {
            ForEach(viewModel.data, id: \.hashValue) { icon in
                HStack {
                    switch icon.type {
                    case .positive:
                        if let data = icon.data,
                           let image = UIImage(data: data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48)
                        } else {
                            Text("⚠️")
                        }

                    case .negative:
                        Text("🟠")
                    }

                    Text(icon.domain)
                }
            }
        }, header: {
            Text("\(viewModel.data.count) cached icons")
        })
    }
}
