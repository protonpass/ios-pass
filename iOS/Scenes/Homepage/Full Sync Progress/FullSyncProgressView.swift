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

import Client
import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

struct FullSyncProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDetail = false
    @StateObject private var viewModel: FullSyncProgressViewModel
    var onContinue: (() -> Void)?

    init(mode: FullSyncProgressViewModel.Mode) {
        _viewModel = .init(wrappedValue: .init(mode: mode))
    }

    var body: some View {
        switch viewModel.mode {
        case .fullSync:
            NavigationView {
                realBody
                    .background(PassColor.backgroundNorm.toColor)
            }
            .navigationViewStyle(.stack)
        case .logIn:
            realBody
        }
    }
}

private extension FullSyncProgressView {
    @ViewBuilder
    var realBody: some View {
        ZStack {
            if viewModel.isDoneSynching {
                doneView
                    .navigationBarHidden(true)
            } else {
                inProgressView
                    .navigationTitle("Syncing items...")
            }
        }
        .animation(.default, value: viewModel.isDoneSynching)
    }
}

private extension FullSyncProgressView {
    var inProgressView: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if !viewModel.mode.isFullSync {
                        Text("Syncing items...")
                            .font(.title3.bold())
                            .foregroundColor(PassColor.textNorm.toColor)
                    }

                    Text("We are downloading and decrypting your items. This might take a few minutes.")
                        .foregroundColor(PassColor.textNorm.toColor)
                        .padding(.vertical, viewModel.mode.isFullSync ? 0 : nil)
                        .fixedSize(horizontal: false, vertical: true)

                    if viewModel.progresses.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.progresses) { progress in
                            VaultSyncProgressView(progress: progress)
                                .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .animation(.default, value: viewModel.progresses.count)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private extension FullSyncProgressView {
    var doneView: some View {
        VStack {
            Spacer()

            Image(uiImage: PassIcon.fullSyncDone)
                .resizable()
                .scaledToFit()
                .frame(width: 156)

            Text("Sync complete")
                .font(.title2.bold())
                .foregroundColor(PassColor.textNorm.toColor)
                .padding(.top)

            if !viewModel.mode.isFullSync {
                Text("The app is now ready to use")
                    .foregroundColor(PassColor.textNorm.toColor)
            }

            Spacer()

            CapsuleTextButton(title: "Continue".localized,
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNormMajor1,
                              action: handleContinuation)
                .padding()
        }
    }
}

private extension FullSyncProgressView {
    func handleContinuation() {
        switch viewModel.mode {
        case .fullSync:
            dismiss()
        case .logIn:
            onContinue?()
        }
    }
}
