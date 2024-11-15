//
// RetryableErrorCellView.swift
// Proton Pass - Created on 07/10/2024.
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

import SwiftUI

public struct RetryableErrorCellView: View {
    let errorMessage: String
    let textColor: Color
    let onRetry: () -> Void
    let buttonColor: UIColor

    public init(errorMessage: String,
                textColor: Color = PassColor.passwordInteractionNormMajor2.toColor,
                buttonColor: UIColor = PassColor.interactionNormMajor2,
                onRetry: @escaping () -> Void) {
        self.errorMessage = errorMessage
        self.textColor = textColor
        self.onRetry = onRetry
        self.buttonColor = buttonColor
    }

    public var body: some View {
        HStack {
            Text(errorMessage)
                .font(.callout)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            RetryButton(tintColor: buttonColor) { onRetry() }
        }
    }
}
