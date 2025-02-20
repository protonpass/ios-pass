//
// ImportFromChromeInstructions.swift
// Proton Pass - Created on 11/02/2025.
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

private enum ImportFromChromeStep: Sendable, CaseIterable, Identifiable {
    case first, second, third, fourth

    var id: String {
        number
    }

    var number: String {
        switch self {
        case .first: "1"
        case .second: "2"
        case .third: "3"
        case .fourth: "4"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .first:
            "Open **Chrome** menu"
        case .second:
            "Go to **Password manager** and tap on **Settings**"
        case .third:
            "Tap **Export passwords**"
        case .fourth:
            "Select **Import to Proton Pass**"
        }
    }
}

public struct ImportFromChromeInstructions: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        VStack(spacing: 20) {
            ForEach(ImportFromChromeStep.allCases) { step in
                row(for: step)
            }

            CapsuleTextButton(title: #localized("Open Chrome"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNormMajor1,
                              action: openChrome)
                .padding(.top, 40)

            Spacer()
        }
        .fullSheetBackground()
        .padding(.horizontal)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)
            }

            ToolbarItem(placement: .principal) {
                Text("Import from Chrome")
                    .navigationTitleText()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationStackEmbeded()
    }

    private func row(for step: ImportFromChromeStep) -> some View {
        HStack(spacing: 10) {
            Text(step.number)
                .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                .fontWeight(.medium)
                .padding(10)
                .background(Circle().stroke(PassColor.interactionNormMinor1.toColor,
                                            lineWidth: 1))
            Text(step.description)
                .foregroundStyle(PassColor.textNorm.toColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openChrome() {
        if let url = URL(string: "googlechrome://"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            dismiss()
        }
    }
}
