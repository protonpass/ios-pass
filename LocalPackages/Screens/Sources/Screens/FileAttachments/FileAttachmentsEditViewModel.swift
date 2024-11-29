//
// FileAttachmentsEditViewModel.swift
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

import DocScanner
import Entities
import UIKit
import UseCases

@MainActor
final class FileAttachmentsEditViewModel: ObservableObject {
    let handler: any FileAttachmentsEditHandler

    private var generateDatedFileName: any GenerateDatedFileNameUseCase {
        handler.provideGenerateDatedFileNameUseCase()
    }

    private var writeToTemporaryDirectory: any WriteToTemporaryDirectoryUseCase {
        handler.provideWriteToTemporaryDirectoryUseCase()
    }

    init(handler: any FileAttachmentsEditHandler) {
        self.handler = handler
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
                guard let document = scanResult as? ScannedDocument else {
                    throw PassError.fileAttachment(.noDocumentScanned)
                }
                let text = document.scannedPages.flatMap(\.text).joined(separator: "\n")
                let fileName = generateDatedFileName(prefix: "Document",
                                                     extension: "txt",
                                                     date: .now)

                guard let data = text.data(using: .utf8) else {
                    throw PassError.fileAttachment(.noDocumentScanned)
                }
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
