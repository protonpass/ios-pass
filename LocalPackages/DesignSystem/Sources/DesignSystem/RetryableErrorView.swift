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
    let error: any Error
    let onShareLogs: (() -> Void)?
    let onRetry: () -> Void

    public enum Mode: Sendable {
        /// Full-page error view, error message displayed  with retry button below
        case vertical(textColor: UIColor)
        /// Inlined error view, error message displayed with retry button on the right
        case horizontal(textColor: UIColor)

        var isVertical: Bool {
            if case .vertical = self {
                true
            } else {
                false
            }
        }

        public static var defaultVertical: Mode {
            .vertical(textColor: PassColor.textNorm)
        }

        public static var defaultHorizontal: Mode {
            .horizontal(textColor: PassColor.passwordInteractionNormMajor2)
        }
    }

    public init(mode: Mode = .defaultVertical,
                tintColor: UIColor = PassColor.interactionNorm,
                error: any Error,
                onShareLogs: (() -> Void)? = nil,
                onRetry: @escaping () -> Void) {
        self.mode = mode
        self.tintColor = tintColor
        self.error = error
        self.onRetry = onRetry
        self.onShareLogs = onShareLogs
        if onShareLogs != nil {
            assert(mode.isVertical, "Sharing logs only supported in vertical mode")
        }
    }

    public var body: some View {
        switch mode {
        case let .vertical(textColor):
            VStack(spacing: DesignConstant.sectionPadding) {
                Text(verbatim: error.localizedDebugDescription)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor.toColor)
                retryButton
                shareLogsButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .horizontal(textColor):
            HStack {
                Text(verbatim: error.localizedDebugDescription)
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

    @ViewBuilder
    var shareLogsButton: some View {
        if let onShareLogs {
            Button(action: onShareLogs) {
                Text("Share logs", bundle: .module)
                    .foregroundStyle(tintColor.toColor)
            }
        }
    }
}

private extension Error {
    var localizedDebugDescription: String {
        if let debugDescription = (self as? CustomDebugStringConvertible)?.debugDescription,
           debugDescription != localizedDescription {
            "\(localizedDescription) \(debugDescription)"
        } else {
            localizedDescription
        }
    }
}
