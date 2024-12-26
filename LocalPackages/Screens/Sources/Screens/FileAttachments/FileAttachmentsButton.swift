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

import AVFoundation
import DesignSystem
import DocScanner
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct FileAttachmentsButton: View {
    @StateObject private var viewModel: FileAttachmentsButtonViewModel
    @State private var showCameraUnavailable = false
    @State private var showCamera = false
    @State private var showDocScanner = false
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false

    private let style: Style
    private let handler: any FileAttachmentsEditHandler

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
        .cameraUnavailableAlert(isPresented: $showCameraUnavailable)
        .alert("No Text Found",
               isPresented: $viewModel.showNoTextFound,
               actions: { Button(action: {}, label: { Text("OK") }) },
               message: {
                   // swiftlint:disable:next line_length
                   Text("No text could be detected in the image. Please try again, ensuring the text is clear, well-lit, and within the camera's focus.")
               })
        .sheet(isPresented: $viewModel.showTextConfirmation) {
            ScannedTextEditor(text: $viewModel.scannedTextToBeConfirmed,
                              primaryTintColor: handler.fileAttachmentsSectionPrimaryColor,
                              secondaryTintColor: handler.fileAttachmentsSectionSecondaryColor,
                              onSave: { viewModel.confirmScannedText() })
                .interactiveDismissDisabled()
        }
    }

    private func handle(_ method: FileAttachmentMethod) {
        guard !handler.isFreeUser else {
            handler.upsellFileAttachments()
            return
        }
        switch method {
        case .takePhoto:
            checkCameraPermission {
                showCamera.toggle()
            }
        case .scanDocuments:
            checkCameraPermission {
                showDocScanner.toggle()
            }
        case .choosePhotoOrVideo:
            showPhotosPicker.toggle()
        case .chooseFile:
            showFileImporter.toggle()
        }
    }

    private func checkCameraPermission(onSuccess: () -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized, .notDetermined:
            onSuccess()
        case .denied, .restricted:
            showCameraUnavailable.toggle()
        @unknown default:
            showCameraUnavailable.toggle()
        }
    }
}

private struct ScannedTextEditor: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var showDiscardChangesAlert = false
    @Binding var text: String
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor
    let onSave: () -> Void

    var body: some View {
        TextEditor(text: $text)
            .scrollContentBackground(.hidden)
            .focused($isFocused)
            .fullSheetBackground()
            .toolbar { toolbar }
            .onAppear { isFocused = true }
            .navigationStackEmbeded()
            .discardChangesAlert(isPresented: $showDiscardChangesAlert,
                                 onDiscard: dismiss.callAsFunction)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: primaryTintColor,
                         backgroundColor: secondaryTintColor,
                         accessibilityLabel: "Close",
                         action: { showDiscardChangesAlert.toggle() })
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Save"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: primaryTintColor,
                                        disableBackgroundColor: secondaryTintColor,
                                        disabled: text.isEmpty,
                                        action: {
                                            onSave()
                                            dismiss()
                                        })
                                        .accessibilityLabel("Save")
                                        .animation(.default, value: text.isEmpty)
        }
    }
}
