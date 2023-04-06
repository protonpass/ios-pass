//
// LogsView.swift
// Proton Pass - Created on 31/03/2023.
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

struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: LogsViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: PassColor.backgroundNorm)
                    .ignoresSafeArea()

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
                            dismissButton
                        }
                    }
                } else {
                    logs
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }

    private var dismissButton: some View {
        CircleButton(icon: IconProvider.cross,
                     iconColor: PassColor.interactionNorm,
                     backgroundColor: PassColor.interactionNormMinor2,
                     action: dismiss.callAsFunction)
    }

    private var logs: some View {
        ScrollViewReader { value in
            List {
                ForEach(viewModel.formattedEntries, id: \.self) { entry in
                    Text(entry)
                        .font(.caption)
                        .id(entry)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    dismissButton
                }

                ToolbarItem(placement: .principal) {
                    Text(viewModel.module.title)
                        .font(.callout.bold())
                        .onTapGesture {
                            withAnimation {
                                value.scrollTo(viewModel.formattedEntries.last ?? "")
                            }
                        }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    CapsuleLabelButton(icon: IconProvider.arrowUpFromSquare,
                                       title: "Share",
                                       backgroundColor: PassColor.interactionNorm,
                                       disabled: false,
                                       action: viewModel.shareLogs)
                }
            }
        }
    }
}
