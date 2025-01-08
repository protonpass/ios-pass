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
import Core
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
    @State private var capturedImageToEdit: UIImage?
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
        if handler.isFreeUser {
            attachFileButton {
                handler.upsellFileAttachments()
            }
        } else {
            content
        }
    }

    private var content: some View {
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
            attachFileButton()
        })
        .sheet(isPresented: $showCamera) {
            CameraView {
                capturedImageToEdit = $0
            }
        }
        .sheet(isPresented: $capturedImageToEdit.mappedToBool()) {
            if let capturedImageToEdit {
                CapturedPhotoEditor(capturedImage: capturedImageToEdit,
                                    primaryTintColor: handler.fileAttachmentsSectionPrimaryColor,
                                    secondaryTintColor: handler.fileAttachmentsSectionSecondaryColor,
                                    onSave: viewModel.handleCapturedPhoto)
                    .interactiveDismissDisabled()
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

    @ViewBuilder
    private func attachFileButton(_ action: (() -> Void)? = nil) -> some View {
        switch style {
        case .circle:
            CircleButton(icon: IconProvider.paperClipVertical,
                         iconColor: handler.fileAttachmentsSectionPrimaryColor,
                         backgroundColor: handler.fileAttachmentsSectionSecondaryColor,
                         action: action)

        case .capsule:
            CapsuleTextButton(title: #localized("Attach a file"),
                              titleColor: handler.fileAttachmentsSectionPrimaryColor,
                              backgroundColor: handler.fileAttachmentsSectionSecondaryColor,
                              height: 48,
                              action: action)
        }
    }

    private func handle(_ method: FileAttachmentMethod) {
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
            .toolbar {
                EditorToolbar(primaryTintColor: primaryTintColor,
                              secondaryTintColor: secondaryTintColor,
                              saveable: !text.isEmpty,
                              onClose: { showDiscardChangesAlert.toggle() },
                              onSave: {
                                  onSave()
                                  dismiss()
                              })
            }
            .onAppear { isFocused = true }
            .navigationStackEmbeded()
            .discardChangesAlert(isPresented: $showDiscardChangesAlert,
                                 onDiscard: dismiss.callAsFunction)
    }
}

private struct CapturedPhotoEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage
    @State private var quality: Float
    @State private var bytesCount: Int
    @State private var editing = false
    @State private var showDiscardChangesAlert = false
    private let capturedImage: UIImage
    private let formatter: ByteCountFormatter
    private let primaryTintColor: UIColor
    private let secondaryTintColor: UIColor
    private let onSave: (CapturedPhoto) -> Void

    init(capturedImage: UIImage,
         defaultQuality: Float = 50.0,
         formatter: ByteCountFormatter = Constants.Attachment.formatter,
         primaryTintColor: UIColor,
         secondaryTintColor: UIColor,
         onSave: @escaping (CapturedPhoto) -> Void) {
        _image = .init(initialValue: capturedImage)
        _quality = .init(initialValue: defaultQuality)
        _bytesCount = .init(initialValue: capturedImage
            .jpegData(compressionQuality: CGFloat(defaultQuality) / 100.0)?.count ?? 0)

        self.formatter = formatter

        self.capturedImage = capturedImage
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
        self.onSave = onSave
    }

    var body: some View {
        VStack {
            Image(uiImage: image)
                .resizable()
                .showSpinner(editing)

            Slider(value: $quality,
                   in: 10...100,
                   step: 10,
                   label: {
                       EmptyView()
                   },
                   minimumValueLabel: {
                       Text(verbatim: "10%")
                           .foregroundStyle(PassColor.textNorm.toColor)
                   },
                   maximumValueLabel: {
                       Text(verbatim: "100%")
                           .foregroundStyle(PassColor.textNorm.toColor)
                   },
                   onEditingChanged: { editing in
                       self.editing = editing
                       if quality == 100 {
                           image = capturedImage
                           bytesCount = capturedImage.pngData()?.count ?? 0
                       } else if let data = compressedImageData(),
                                 let image = UIImage(data: data) {
                           self.image = image
                           bytesCount = data.count
                       }
                   })
                   .padding([.top, .horizontal])

            HStack {
                if let size = formatter.string(for: bytesCount) {
                    Text(verbatim: size)
                        .if(editing) { view in
                            view.redacted(reason: .placeholder)
                        }
                }
                Text(verbatim: "(\("\(String(format: "%.0f", quality))%"))")
            }
            .foregroundStyle(PassColor.textNorm.toColor)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.bottom)
        .tint(primaryTintColor.toColor)
        .animation(.default, value: quality)
        .animation(.default, value: editing)
        .fullSheetBackground()
        .toolbar {
            EditorToolbar(primaryTintColor: primaryTintColor,
                          secondaryTintColor: secondaryTintColor,
                          saveable: true,
                          onClose: { showDiscardChangesAlert.toggle() },
                          onSave: {
                              if quality == 100 {
                                  onSave(.png(capturedImage.pngData()))
                              } else {
                                  onSave(.jpeg(compressedImageData()))
                              }
                              dismiss()
                          })
        }
        .navigationStackEmbeded()
        .discardChangesAlert(isPresented: $showDiscardChangesAlert,
                             onDiscard: dismiss.callAsFunction)
    }

    private func compressedImageData() -> Data? {
        capturedImage.jpegData(compressionQuality: CGFloat(quality) / 100.0)
    }
}

private struct EditorToolbar: ToolbarContent {
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor
    let saveable: Bool
    let onClose: () -> Void
    let onSave: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: primaryTintColor,
                         backgroundColor: secondaryTintColor,
                         accessibilityLabel: "Close",
                         action: onClose)
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Save"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: primaryTintColor,
                                        disableBackgroundColor: secondaryTintColor,
                                        disabled: !saveable,
                                        action: onSave)
                .accessibilityLabel("Save")
                .animation(.default, value: saveable)
        }
    }
}
