//
// FullSyncProgressView.swift
// Proton Pass - Created on 11/09/2023.
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

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

struct FullSyncProgressView: View {
    @State private var isShowingDetail = false
    @StateObject private var viewModel: FullSyncProgressViewModel

    init(mode: FullSyncProgressViewModel.Mode) {
        _viewModel = .init(wrappedValue: .init(mode: mode))
    }

    var body: some View {
        switch viewModel.mode {
        case .fullSync:
            NavigationStack {
                realBody
                    .background(PassColor.backgroundNorm.toColor)
            }
        case .logIn:
            realBody
        }
    }
}

private extension FullSyncProgressView {
    @ViewBuilder
    var realBody: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            if let error = viewModel.error {
                RetryableErrorView(error: error, onRetry: retry)
                    .padding()
            } else {
                VStack {
                    Spacer()
                    overallProgressView
                    if isShowingDetail {
                        allProgressesView
                    } else {
                        Spacer()
                        Spacer()
                        moreInfoButton
                            .padding(.bottom)
                    }
                }
                .animation(.default, value: isShowingDetail)
            }
        }
        .animation(.default, value: viewModel.error == nil)
    }

    func retry() {
        Task {
            await viewModel.retry()
        }
    }
}

private extension FullSyncProgressView {
    var overallProgressView: some View {
        VStack(alignment: .center) {
            FullSyncInProgressView()
                .frame(width: 80)

            Text("Syncing items...")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.bottom, 8)

            Text("We are downloading and decrypting your items.")
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm.toColor)

            Text("This might take a few minutes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm.toColor)

            Text("Please keep the app open.")
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm.toColor)
                .padding(.top, 8)
                .padding(.bottom, 16)

            if viewModel.progresses.isEmpty {
                ProgressView()
            } else {
                ProgressView(value: Float(viewModel.numberOfSyncedVaults()),
                             total: Float(viewModel.progresses.count))
                    .frame(width: 200)
                    .animation(.default, value: viewModel.numberOfSyncedVaults())
                    .progressViewStyle(.pass)
            }
        }
        .animation(.default, value: viewModel.progresses.isEmpty)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
}

private extension FullSyncProgressView {
    var moreInfoButton: some View {
        Button(action: {
            isShowingDetail = true
        }, label: {
            VStack(alignment: .center) {
                Text("More info")
                Label(title: { Text(verbatim: "") },
                      icon: { Image(systemName: "chevron.down") })
            }
            .foregroundStyle(PassColor.textWeak.toColor)
        })
        .buttonStyle(.plain)
        .disabled(viewModel.progresses.isEmpty)
        .opacity(viewModel.progresses.isEmpty ? 0 : 1)
    }
}

private extension FullSyncProgressView {
    var allProgressesView: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(viewModel.progresses) { progress in
                    VaultSyncProgressView(progress: progress)
                        .padding(.vertical, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .animation(.default, value: viewModel.progresses.count)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
