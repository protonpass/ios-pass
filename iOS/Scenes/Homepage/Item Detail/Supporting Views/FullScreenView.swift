//
// FullScreenView.swift
// Proton Pass - Created on 18/11/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import CoreImage.CIFilterBuiltins
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct FullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .text
    @State private var originalBrightness: CGFloat = 0.5
    @State private var percentage: Double = 0.5
    let text: String
    let theme: Theme

    enum Mode {
        case text, qr

        var systemImageName: String {
            switch self {
            case .text: return "textformat.abc"
            case .qr: return "qrcode"
            }
        }

        var oppositeMode: Mode {
            switch self {
            case .text: return .qr
            case .qr: return .text
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Group {
                    switch mode {
                    case .text:
                        FullScreenTextView(originalBrightness: $originalBrightness,
                                           percentage: $percentage,
                                           text: text)
                    case .qr:
                        QrCodeView(text: text)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: mode)
            .itemDetailBackground(theme: theme)
            .toolbar { toolbarContent }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = CGFloat(1.0)
        }
        .onDisappear {
            UIScreen.main.brightness = originalBrightness
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                self.mode = mode.oppositeMode
            }, label: {
                Image(systemName: mode.oppositeMode.systemImageName)
                    .foregroundColor(Color(uiColor: PassColor.interactionNorm))
            })
        }
    }
}

private struct FullScreenTextView: View {
    @Binding var originalBrightness: CGFloat
    @Binding var percentage: Double
    let text: String

    var body: some View {
        VStack {
            Spacer()
            Text(verbatim: text)
                .font(.system(size: (percentage + 1) * 24))
                .fontWeight(.semibold)
            Spacer()
            HStack {
                Text("A")
                Slider(value: $percentage)
                    .tint(Color(uiColor: PassColor.interactionNorm))
                Text("A")
                    .font(.title)
            }
        }
    }
}

private struct QrCodeView: View {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    var text: String

    var body: some View {
        Image(uiImage: qrCodeImage())
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }

    private func qrCodeImage() -> UIImage {
        let data = Data(text.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let qrCodeImage = filter.outputImage,
           let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
            return .init(cgImage: qrCodeCGImage)
        }
        return .init()
    }
}
