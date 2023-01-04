//
// DeviceLogsView.swift
// Proton Pass - Created on 02/01/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct DeviceLogsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: DeviceLogsViewModel

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    RetryableErrorView(errorMessage: error.messageForTheUser,
                                       onRetry: viewModel.loadLogs)
                } else if viewModel.entries.isEmpty {
                    VStack {
                        Image(systemName: "doc")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No logs")
                            .foregroundColor(.secondary)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: dismiss.callAsFunction) {
                                Image(uiImage: IconProvider.cross)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                } else {
                    logs
                }
            }
            .navigationTitle(viewModel.type.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private var logs: some View {
        ScrollViewReader { value in
            List {
                ForEach(viewModel.formattedEntries, id: \.self) { entry in
                    Text(entry)
                        .font(.caption)
                        .id(entry)
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: dismiss.callAsFunction) {
                        Image(uiImage: IconProvider.cross)
                    }
                    .foregroundColor(.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            withAnimation {
                                value.scrollTo(viewModel.formattedEntries.last ?? "")
                            }
                        }, label: {
                            Image(systemName: "arrow.down.doc")
                        })

                        Button(action: viewModel.shareLogs) {
                            Image(uiImage: IconProvider.arrowUpFromSquare)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}
