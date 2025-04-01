//
// FileAttachmentPreview.swift
// Proton Pass - Created on 21/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct FileAttachmentPreview: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FileAttachmentPreviewModel
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor

    public init(mode: FileAttachmentPreviewMode,
                primaryTintColor: UIColor,
                secondaryTintColor: UIColor) {
        _viewModel = .init(wrappedValue: .init(mode: mode))
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
    }

    public var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            switch viewModel.url {
            case .fetching:
                ProgressView(value: viewModel.progress,
                             label: {
                                 Label(title: {
                                     if let fileName = viewModel.fileName {
                                         Text(verbatim: fileName)
                                             .foregroundStyle(PassColor.textNorm.toColor)
                                     }
                                 }, icon: {
                                     ProgressView()
                                         .controlSize(.small)
                                 })
                             },
                             currentValueLabel: {
                                 if let detail = viewModel.progressDetail {
                                     Text(verbatim: detail)
                                         .foregroundStyle(PassColor.textWeak.toColor)
                                 }
                             })
                             .tint(primaryTintColor.toColor)
                             .padding()

            case let .fetched(url):
                QuickLookPreview(url: url)
                    .padding(.top, 8)
                    .ignoresSafeArea(edges: .bottom)

            case let .error(error):
                RetryableErrorView(tintColor: primaryTintColor,
                                   error: error,
                                   onRetry: { Task { await viewModel.fetchFile() } })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(primaryTintColor.toColor)
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: viewModel.url)
        .navigationStackEmbeded()
        .task { await viewModel.fetchFile() }
        .sheet(isPresented: $viewModel.urlToSave.mappedToBool()) {
            if let url = viewModel.urlToSave {
                ExportDocumentView(url: url)
                    .onDisappear {
                        dismissIfFileIsRemoved(url)
                    }
            }
        }
        .sheet(isPresented: $viewModel.urlToShare.mappedToBool()) {
            if let url = viewModel.urlToShare {
                ActivityView(items: [url])
                    .onDisappear {
                        dismissIfFileIsRemoved(url)
                    }
            }
        }
    }
}

private extension FileAttachmentPreview {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: primaryTintColor,
                         backgroundColor: secondaryTintColor,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .principal) {
            if let fileName = viewModel.fileName {
                Text(verbatim: fileName)
                    .lineLimit(1)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.medium)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if case let .fetched(url) = viewModel.url {
                Menu(content: {
                    LabelButton(title: "Save",
                                icon: IconProvider.arrowDownCircle,
                                action: { viewModel.urlToSave = url })
                    LabelButton(title: "Share",
                                icon: IconProvider.arrowUpFromSquare,
                                action: { viewModel.urlToShare = url })
                }, label: {
                    CircleButton(icon: IconProvider.threeDotsVertical,
                                 iconColor: primaryTintColor,
                                 backgroundColor: secondaryTintColor)
                })
            }
        }
    }

    // When file is saved to filesystem (via Files app) from export or share sheet,
    // the system removes the file because it's in temporary folder.
    // So the previous URL to the file becomes obsolete.
    // As a result, we double check if the file still exists or not.
    // If not, we dismiss this preview in order for users to manually enter the preview
    // to download the file again. Otherwise, if the users try to save or share again,
    // the app will crash because file no more exists at the previous URL
    func dismissIfFileIsRemoved(_ url: URL) {
        if !FileManager.default.fileExists(atPath: url.path()) {
            dismiss()
        }
    }
}
