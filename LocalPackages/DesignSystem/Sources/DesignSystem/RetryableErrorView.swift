//
// RetryableErrorView.swift
// Proton Pass - Created on 20/09/2022.
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

import Macro
import SwiftUI

public struct RetryableErrorView: View {
    let mode: Mode
    let tintColor: UIColor
    let errorMessage: String
    let onRetry: () -> Void

    public enum Mode: Sendable {
        /// Full-page error view, error message displayed  with retry button below
        case vertical(textColor: UIColor)
        /// Inlined error view, error message displayed with retry button on the right
        case horizontal(textColor: UIColor)

        public static var defaultVertical: Mode {
            .vertical(textColor: PassColor.textNorm)
        }

        public static var defaultHorizontal: Mode {
            .horizontal(textColor: PassColor.passwordInteractionNormMajor2)
        }
    }

    public init(mode: Mode = .defaultVertical,
                tintColor: UIColor = PassColor.interactionNorm,
                errorMessage: String,
                onRetry: @escaping () -> Void) {
        self.mode = mode
        self.tintColor = tintColor
        self.errorMessage = errorMessage
        self.onRetry = onRetry
    }

    public var body: some View {
        switch mode {
        case let .vertical(textColor):
            VStack {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor.toColor)
                retryButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .horizontal(textColor):
            HStack {
                Text(errorMessage)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(textColor.toColor)
                Spacer()
                retryButton
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private extension RetryableErrorView {
    var retryButton: some View {
        Label(#localized("Retry", bundle: .module), systemImage: "arrow.counterclockwise")
            .foregroundStyle(tintColor.toColor)
            .labelStyle(.rightIcon)
            .buttonEmbeded(action: onRetry)
    }
}
