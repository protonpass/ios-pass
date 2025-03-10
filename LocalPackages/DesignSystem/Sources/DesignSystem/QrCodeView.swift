//
// QrCodeView.swift
// Proton Pass - Created on 10/03/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import CoreImage.CIFilterBuiltins
import SwiftUI

public struct QrCodeView: View {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Image(uiImage: qrCodeImage())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }
}

private extension QrCodeView {
    func qrCodeImage() -> UIImage {
        let data = Data(text.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let qrCodeImage = filter.outputImage,
           let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
            return .init(cgImage: qrCodeCGImage)
        }
        return .init()
    }
}
