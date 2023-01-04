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
                switch viewModel.state {
                case .loading:
                    ProgressView()
                case .loaded(let logs):
                    contentView(logs)
                case .error(let error):
                    RetryableErrorView(errorMessage: error.messageForTheUser,
                                       onRetry: viewModel.loadLogs)
                }
            }
            .navigationTitle(viewModel.type.title)
        }
        .navigationViewStyle(.stack)
    }

    private func contentView(_ logs: String) -> some View {
        ScrollView {
            Text(logs)
                .padding()
        }
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: dismiss.callAsFunction) {
                Image(uiImage: IconProvider.cross)
            }
            .foregroundColor(.primary)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.shareLogs) {
                Image(uiImage: IconProvider.arrowUpFromSquare)
            }
            .foregroundColor(.primary)
        }
    }
}
