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

import Core
import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct LogsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: LogsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                PassColor.backgroundNorm.toColor
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    RetryableErrorView(errorMessage: error.localizedDescription,
                                       onRetry: { viewModel.loadLogs() })
                } else if viewModel.entries.isEmpty {
                    VStack {
                        Image(systemName: "doc")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("No logs")
                            .foregroundStyle(.secondary)
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            dismissButton
                        }
                    }
                } else {
                    content
                        .showSpinner(viewModel.sharingLogs)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(PassColor.backgroundNorm.toColor)
        }
    }

    private var dismissButton: some View {
        CircleButton(icon: IconProvider.cross,
                     iconColor: PassColor.interactionNormMajor2,
                     backgroundColor: PassColor.interactionNormMinor1,
                     accessibilityLabel: "Close",
                     action: dismiss.callAsFunction)
    }

    private var content: some View {
        ScrollViewReader { value in
            VStack {
                if Bundle.main.isQaBuild {
                    filterButton
                        .padding(.horizontal)
                }

                if viewModel.formattedEntries.isEmpty {
                    Spacer()
                    noFilteredLogsMessage
                    Spacer()
                } else {
                    logs
                }
            }
            .frame(maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    dismissButton
                }

                ToolbarItem(placement: .principal) {
                    Text(viewModel.module.logTitle)
                        .font(.callout.bold())
                        .onTapGesture {
                            withAnimation {
                                value.scrollTo(viewModel.formattedEntries.last ?? "")
                            }
                        }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    CapsuleLabelButton(icon: IconProvider.arrowUpFromSquare,
                                       title: #localized("Share"),
                                       titleColor: PassColor.textInvert,
                                       backgroundColor: PassColor.interactionNorm,
                                       action: { viewModel.shareLogs() })
                }
            }
        }
    }
}

private extension LogsView {
    var filterButton: some View {
        Menu(content: {
            Button(action: {
                viewModel.logLevel = nil
            }, label: {
                Text("All")
            })

            ForEach(LogLevel.allCases, id: \.self) { level in
                Button(action: {
                    viewModel.logLevel = level
                }, label: {
                    Text(level.descriptionWithEmoji)
                })
            }
        }, label: {
            if let level = viewModel.logLevel {
                Text(verbatim: "Log level (\(level.descriptionWithEmoji))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.callout.weight(.medium))
            } else {
                Text(verbatim: "Log level (All)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.callout.weight(.medium))
            }
        })
        .animationsDisabled()
        .buttonStyle(.plain)
        .foregroundStyle(PassColor.interactionNormMajor2.toColor)
    }

    var noFilteredLogsMessage: some View {
        Text("No logs for \(viewModel.logLevel?.descriptionWithEmoji ?? "")")
    }

    var logs: some View {
        List {
            ForEach(viewModel.formattedEntries, id: \.self) { entry in
                Text(entry)
                    .font(.caption)
                    .id(entry)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
}
