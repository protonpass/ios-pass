//
// WrappedCodeScannerView.swift
// Proton Pass - Created on 11/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import CodeScanner
import Core
import DesignSystem
import Factory
import ProtonCoreUIFoundations
import SwiftUI

public struct WrappedCodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isGaleryPresented = false
    private let theme = resolve(\SharedToolingContainer.theme)
    let completion: (Result<String, Error>) -> Void

    public init(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
    }

    public var body: some View {
        NavigationView {
            CodeScannerView(codeTypes: [.qr],
                            simulatedData: "otpauth://totp/SimpleLogin:john.doe%40example.com?secret=CKTQQJVWT5IXTGDB&amp;issuer=SimpleLogin",
                            isGalleryPresented: $isGaleryPresented) { result in
                dismiss()
                switch result {
                case let .success(scanResult):
                    completion(.success(scanResult.string))
                case let .failure(error):
                    completion(.failure(error))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isGaleryPresented.toggle()
                    }, label: {
                        Image(systemName: "photo.on.rectangle.angled")
                            .foregroundColor(Color(uiColor: PassColor.interactionNormMajor1))
                    })
                }
            }
        }
        .navigationViewStyle(.stack)
        .theme(theme)
    }
}
