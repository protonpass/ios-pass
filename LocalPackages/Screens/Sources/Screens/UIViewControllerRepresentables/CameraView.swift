//
// CameraView.swift
// Proton Pass - Created on 28/11/2024.
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

import SwiftUI

public struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: ((UIImage) -> Void)?
    let onTemporarilySaved: ((Result<URL, any Error>) -> Void)?

    public init(onCapture: ((UIImage) -> Void)? = nil,
                onTemporarilySaved: ((Result<URL, any Error>) -> Void)? = nil) {
        self.onCapture = onCapture
        self.onTemporarilySaved = onTemporarilySaved
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ viewController: UIImagePickerController,
                                       context: Context) {
        // Not applicable
    }

    public final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [
            UIImagePickerController
                .InfoKey: Any
        ]) {
            defer { parent.dismiss() }

            guard let image = info[.originalImage] as? UIImage else {
                assertionFailure("Expect an UIImage but it's nil")
                return
            }
            parent.onCapture?(image)

            guard let onTemporarilySaved = parent.onTemporarilySaved else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
            let date = formatter.string(from: .now)
            let fileName = "Photo \(date).png"
            let tempDirectory = FileManager.default.temporaryDirectory
            let url = tempDirectory.appendingPathComponent(fileName)
            if let pngData = image.pngData() {
                do {
                    try pngData.write(to: url)
                    onTemporarilySaved(.success(url))
                } catch {
                    onTemporarilySaved(.failure(error))
                }
            }
        }
    }
}
