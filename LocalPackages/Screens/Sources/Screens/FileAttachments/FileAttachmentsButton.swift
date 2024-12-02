//
// FileAttachmentsButton.swift
// Proton Pass - Created on 19/11/2024.
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
import DocScanner
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct FileAttachmentsButton: View {
    @StateObject private var viewModel: FileAttachmentsButtonViewModel
    @State private var showCamera = false
    @State private var showDocScanner = false
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false

    let style: Style
    let handler: any FileAttachmentsEditHandler

    public enum Style {
        case circle, capsule
    }

    public init(style: Style,
                handler: any FileAttachmentsEditHandler) {
        _viewModel = .init(wrappedValue: .init(handler: handler))
        self.style = style
        self.handler = handler
    }

    public var body: some View {
        Menu(content: {
            ForEach(FileAttachmentMethod.allCases, id: \.self) { method in
                Label(title: {
                    Text(method.title)
                }, icon: {
                    Image(uiImage: method.icon)
                        .resizable()
                })
                .buttonEmbeded {
                    handle(method)
                }
            }
        }, label: {
            switch style {
            case .circle:
                CircleButton(icon: IconProvider.paperClipVertical,
                             iconColor: handler.fileAttachmentsSectionPrimaryColor,
                             backgroundColor: handler.fileAttachmentsSectionSecondaryColor)

            case .capsule:
                CapsuleTextButton(title: #localized("Attach a file"),
                                  titleColor: handler.fileAttachmentsSectionPrimaryColor,
                                  backgroundColor: handler.fileAttachmentsSectionSecondaryColor,
                                  height: 48)
            }
        })
        .sheet(isPresented: $showCamera) {
            CameraView {
                viewModel.handleCapturedPhoto($0)
            }
        }
        .sheet(isPresented: $showDocScanner) {
            DocScanner(with: ScanInterpreter(type: .document),
                       completion: { viewModel.handleScanResult($0) })
        }
        .photosPicker(isPresented: $showPhotosPicker,
                      selection: $viewModel.selectedPhotos,
                      maxSelectionCount: 1)
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: false,
                      onCompletion: { result in
                          switch result {
                          case let .success(urls):
                              if let url = urls.first {
                                  handler.handleAttachment(url)
                              }
                          case let .failure(error):
                              handler.handleAttachmentError(error)
                          }
                      })
    }

    private func handle(_ method: FileAttachmentMethod) {
        switch method {
        case .takePhoto:
            showCamera.toggle()
        case .scanDocuments:
            showDocScanner.toggle()
        case .choosePhotoOrVideo:
            showPhotosPicker.toggle()
        case .chooseFile:
            showFileImporter.toggle()
        }
    }
}
