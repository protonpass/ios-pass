//
// FileAttachmentsButtonViewModel.swift
// Proton Pass - Created on 29/11/2024.
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

import Combine
import Core
import DocScanner
import Entities
import PhotosUI
import SwiftUI

enum CapturedPhoto {
    case png(Data?)
    case jpeg(Data?)

    var data: Data {
        get throws {
            switch self {
            case let .png(data):
                guard let data else {
                    throw PassError.fileAttachment(.noPngData)
                }
                return data

            case let .jpeg(data):
                guard let data else {
                    throw PassError.fileAttachment(.noJpegData)
                }
                return data
            }
        }
    }

    var fileExtension: String {
        switch self {
        case .png:
            "png"

        case .jpeg:
            "jpeg"
        }
    }
}

@MainActor
@Observable
final class FileAttachmentsButtonViewModel {
    var selectedPhotos = [PhotosPickerItem]()
    var scannedTextToBeConfirmed = ""
    var showTextConfirmation = false
    var showNoTextFound = false

    @ObservationIgnored
    private var selectedPhotosTask: Task<Void, Never>?
    let handler: any FileAttachmentsEditHandler

    init(handler: any FileAttachmentsEditHandler) {
        self.handler = handler
    }

    func handleCapturedPhoto(_ photo: CapturedPhoto) {
        do {
            let fileName = handler.generateDatedFileName(prefix: "Photo",
                                                         extension: photo.fileExtension)
            let url = try handler.writeToTemporaryDirectory(data: photo.data, fileName: fileName)
            handler.handleAttachment(url)
        } catch {
            handler.handleAttachmentError(error)
        }
    }

    func handleScanResult(_ result: Result<(any ScanResult)?, any Error>) {
        switch result {
        case let .success(scanResult):
            guard let document = scanResult as? ScannedDocument else {
                showNoTextFound = true
                return
            }
            let text = document.scannedPages.flatMap(\.text).joined(separator: "\n")
            if text.isEmpty {
                showNoTextFound = true
            } else {
                scannedTextToBeConfirmed = text
                showTextConfirmation = true
            }

        case let .failure(error):
            handler.handleAttachmentError(error)
        }
    }

    func confirmScannedText() {
        let text = scannedTextToBeConfirmed
        guard !text.isEmpty else { return }
        do {
            let fileName = handler.generateDatedFileName(prefix: "Document", extension: "txt")
            guard let data = text.data(using: .utf8) else { return }
            let url = try handler.writeToTemporaryDirectory(data: data, fileName: fileName)
            handler.handleAttachment(url)
        } catch {
            handler.handleAttachmentError(error)
        }
    }
}

extension FileAttachmentsButtonViewModel {
    func processSelectedPhotos(_ photos: [PhotosPickerItem]) {
        guard let photo = photos.first else { return }

        let previous = selectedPhotosTask
        selectedPhotosTask = Task { [weak self] in
            // Deterministic teardown before we touch the loading indicator, so a
            // superseded load can never hide an indicator this load just showed.
            previous?.cancel()
            await previous?.value

            guard let self, !Task.isCancelled else { return }

            handler.showLoadingIndicator()
            defer { handler.hideLoadingIndicator() }

            do {
                guard let url = try await photo.loadTransferable(type: TempDirectoryTransferableUrl.self)?.value
                else {
                    throw PassError.fileAttachment(.failedToProcessPickedPhotos)
                }
                try Task.checkCancellation()
                selectedPhotos = []
                handler.handleAttachment(url)
            } catch is CancellationError {
                // Superseded by a newer selection. Not user-facing.
            } catch {
                handler.handleAttachmentError(error)
            }
        }
    }
}
