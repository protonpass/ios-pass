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
import UseCases

@MainActor
final class FileAttachmentsButtonViewModel: ObservableObject {
    @Published var selectedPhotos = [PhotosPickerItem]()

    private var selectedPhotosTask: Task<Void, Never>?
    private var cancellable = Set<AnyCancellable>()
    let handler: any FileAttachmentsEditHandler

    private var generateDatedFileName: any GenerateDatedFileNameUseCase {
        handler.provideGenerateDatedFileNameUseCase()
    }

    private var writeToTemporaryDirectory: any WriteToTemporaryDirectoryUseCase {
        handler.provideWriteToTemporaryDirectoryUseCase()
    }

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

    func handleCapturedPhoto(_ image: UIImage?) {
        do {
            guard let pngData = image?.pngData() else {
                throw PassError.fileAttachment(.noPngData)
            }
            let fileName = generateDatedFileName(prefix: "Photo", extension: "png", date: .now)
            let url = try writeToTemporaryDirectory(data: pngData, fileName: fileName)
            handler.handleAttachment(url)
        } catch {
            handler.handleAttachmentError(error)
        }
    }

    func handleScanResult(_ result: Result<(any ScanResult)?, any Error>) {
        do {
            switch result {
            case let .success(scanResult):
                guard let document = scanResult as? ScannedDocument else { return }
                let text = document.scannedPages.flatMap(\.text).joined(separator: "\n")
                guard !text.isEmpty else { return }
                let fileName = generateDatedFileName(prefix: "Document",
                                                     extension: "txt",
                                                     date: .now)

                guard let data = text.data(using: .utf8) else { return }
                let url = try writeToTemporaryDirectory(data: data, fileName: fileName)
                handler.handleAttachment(url)
            case let .failure(error):
                handler.handleAttachmentError(error)
            }
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
