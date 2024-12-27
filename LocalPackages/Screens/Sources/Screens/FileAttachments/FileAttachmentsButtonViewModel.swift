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

enum CapturedPhoto: Sendable {
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
final class FileAttachmentsButtonViewModel: ObservableObject {
    @Published var selectedPhotos = [PhotosPickerItem]()
    @Published var scannedTextToBeConfirmed = ""
    @Published var showTextConfirmation = false
    @Published var showNoTextFound = false

    private var selectedPhotosTask: Task<Void, Never>?
    private var cancellable = Set<AnyCancellable>()
    let handler: any FileAttachmentsEditHandler

    init(handler: any FileAttachmentsEditHandler) {
        self.handler = handler

        $selectedPhotos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] photos in
                guard let self else { return }
                handleSelectedPhotos(photos)
            }
            .store(in: &cancellable)
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
                showNoTextFound.toggle()
                return
            }
            let text = document.scannedPages.flatMap(\.text).joined(separator: "\n")
            if text.isEmpty {
                showNoTextFound.toggle()
            } else {
                scannedTextToBeConfirmed = text
                showTextConfirmation.toggle()
            }

        case let .failure(error):
            handler.handleAttachmentError(error)
        }
    }

    func confirmScannedText() {
        do {
            let fileName = handler.generateDatedFileName(prefix: "Document", extension: "txt")
            guard let data = scannedTextToBeConfirmed.data(using: .utf8) else { return }
            let url = try handler.writeToTemporaryDirectory(data: data, fileName: fileName)
            handler.handleAttachment(url)
        } catch {
            handler.handleAttachmentError(error)
        }
    }
}

private extension FileAttachmentsButtonViewModel {
    func handleSelectedPhotos(_ photos: [PhotosPickerItem]) {
        selectedPhotosTask?.cancel()
        selectedPhotosTask = Task { [weak self] in
            guard let self, let photo = photos.first else { return }
            do {
                guard let url = try await photo.loadTransferable(type: TempDirectoryTransferableUrl.self) else {
                    throw PassError.fileAttachment(.failedToProcessPickedPhotos)
                }
                handler.handleAttachment(url.value)
            } catch {
                handler.handleAttachmentError(error)
            }
        }
    }
}
