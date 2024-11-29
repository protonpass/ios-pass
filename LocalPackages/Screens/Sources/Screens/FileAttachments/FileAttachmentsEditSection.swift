//
// FileAttachmentsEditSection.swift
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
import ProtonCoreUIFoundations
import SwiftUI
import UseCases

@MainActor
public protocol FileAttachmentsEditHandler {
    var fileAttachmentsSectionPrimaryColor: UIColor { get }
    var fileAttachmentsSectionSecondaryColor: UIColor { get }

    func provideGenerateDatedFileNameUseCase() -> any GenerateDatedFileNameUseCase
    func provideWriteToTemporaryDirectoryUseCase() -> any WriteToTemporaryDirectoryUseCase

    func handleAttachment(_ url: URL)
    func handleAttachmentError(_ error: any Error)
    func rename(attachment: FileAttachment, newName: String)
    func delete(attachment: FileAttachment)
    func deleteAllAttachments()
}

public struct FileAttachmentsEditSection: View {
    @StateObject private var viewModel: FileAttachmentsEditViewModel
    @State private var showDeleteAllAlert = false
    @State private var showCamera = false
    @State private var showDocScanner = false
    let files: [FileAttachment]
    let isUploading: Bool
    let handler: any FileAttachmentsEditHandler

    public init(files: [FileAttachment],
                isUploading: Bool,
                handler: any FileAttachmentsEditHandler) {
        _viewModel = .init(wrappedValue: .init(handler: handler))
        self.files = files
        self.isUploading = isUploading
        self.handler = handler
    }

    public var body: some View {
        LazyVStack {
            HStack(spacing: DesignConstant.sectionPadding) {
                ItemDetailSectionIcon(icon: IconProvider.paperClip)

                VStack(alignment: .leading) {
                    Text("Attachments")
                        .foregroundStyle(PassColor.textNorm.toColor)

                    if !files.isEmpty {
                        Text("\(files.count) files")
                            .font(.callout)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    } else if !isUploading {
                        Text("Upload files from your device")
                            .foregroundStyle(PassColor.textWeak.toColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !files.isEmpty {
                    CircleButton(icon: IconProvider.trash,
                                 iconColor: handler.fileAttachmentsSectionPrimaryColor,
                                 iconDisabledColor: handler.fileAttachmentsSectionPrimaryColor,
                                 backgroundColor: handler.fileAttachmentsSectionSecondaryColor,
                                 backgroundDisabledColor: handler.fileAttachmentsSectionSecondaryColor,
                                 action: { showDeleteAllAlert.toggle() })
                        .opacityReduced(isUploading)
                }
            }

            ForEach(files) { file in
                FileAttachmentRow(file: file,
                                  onRename: { handler.rename(attachment: file, newName: $0) },
                                  onDelete: { handler.delete(attachment: file) })
                    .padding(.vertical, DesignConstant.sectionPadding / 2)
                if file != files.last {
                    PassDivider()
                }
            }

            FileAttachmentsButton(style: .capsule,
                                  iconColor: handler.fileAttachmentsSectionPrimaryColor,
                                  backgroundColor: handler.fileAttachmentsSectionSecondaryColor,
                                  onSelect: { handle($0) })
                .opacityReduced(isUploading)
        }
        .animation(.default, value: files)
        .animation(.default, value: isUploading)
        .padding(DesignConstant.sectionPadding)
        .tint(handler.fileAttachmentsSectionPrimaryColor.toColor)
        .roundedEditableSection()
        .alert("Delete all attachments?",
               isPresented: $showDeleteAllAlert,
               actions: {
                   Button("Delete all",
                          role: .destructive,
                          action: { handler.deleteAllAttachments() })
                   Button("Cancel", role: .cancel, action: {})
               },
               message: {
                   Text("This action cannot be undone")
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
    }

    private func handle(_ method: FileAttachmentMethod) {
        switch method {
        case .takePhoto:
            showCamera.toggle()
        case .scanDocuments:
            showDocScanner.toggle()
        case .choosePhotoOrVideo:
            break
        case .chooseFile:
            break
        }
    }
}

private struct FileAttachmentRow: View {
    @State private var name: String
    @State private var icon: UIImage?
    @State private var showRenameAlert = false
    let file: FileAttachment
    let onRename: (String) -> Void
    let onDelete: () -> Void

    init(file: FileAttachment,
         onRename: @escaping (String) -> Void,
         onDelete: @escaping () -> Void) {
        _name = .init(initialValue: file.metadata.name)
        self.file = file
        self.onRename = onRename
        self.onDelete = onDelete
    }

    var body: some View {
        HStack {
            Image(uiImage: icon ?? IconProvider.fileEmpty)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 20)

            VStack(alignment: .leading) {
                Text(file.metadata.name)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(verbatim: "\(file.metadata.size)")
                    .foregroundStyle(PassColor.textWeak.toColor)
            }

            Spacer()

            Menu(content: {
                LabelButton(title: "Rename",
                            icon: PassIcon.rename,
                            action: { showRenameAlert.toggle() })
                Divider()
                LabelButton(title: "Delete",
                            icon: IconProvider.trash,
                            action: onDelete)
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: PassColor.textWeak,
                             backgroundColor: .clear)
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Rename file",
               isPresented: $showRenameAlert,
               actions: {
                   TextField(text: $name, label: { EmptyView() })
                   Button("Rename", action: { onRename(name) })
                       .disabled(name.isEmpty)
                   Button("Cancel", role: .cancel, action: { name = file.metadata.name })
               })
    }
}
