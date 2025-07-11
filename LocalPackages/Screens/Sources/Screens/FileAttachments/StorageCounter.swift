//
// StorageCounter.swift
// Proton Pass - Created on 08/01/2025.
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
//

import Core
import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

public struct StorageCounter: View {
    @State private var showUpsell = false
    private let percentage: Int
    private let detail: String
    private let level: Level
    private let shouldUpsell: Bool
    private let onUpgrade: () -> Void

    private enum Level {
        case low, medium, full

        var textColor: UIColor {
            switch self {
            case .low:
                PassColor.textNorm
            case .medium:
                PassColor.signalWarning
            case .full:
                PassColor.signalDanger
            }
        }

        var textFontWeight: Font.Weight {
            switch self {
            case .low:
                .regular
            default:
                .medium
            }
        }

        var progressColor: UIColor {
            switch self {
            case .low:
                PassColor.signalSuccess
            case .medium:
                PassColor.signalWarning
            case .full:
                PassColor.signalDanger
            }
        }
    }

    public init(used: Int,
                total: Int,
                shouldUpsell: Bool,
                formatter: ByteCountFormatter = Constants.Attachment.formatter,
                onUpgrade: @escaping () -> Void) {
        guard total > 0 else {
            percentage = 100
            detail = "N/A"
            level = .full
            self.shouldUpsell = shouldUpsell
            self.onUpgrade = onUpgrade
            return
        }
        let floatPercentage = Float(used) / Float(total) * 100

        let formattedUsed = formatter.string(fromByteCount: Int64(used))
        let formattedTotal = formatter.string(fromByteCount: Int64(total))

        percentage = floatPercentage > 99.9 ? 100 : Int(floatPercentage)
        detail = #localized("%1$@ of %2$@", formattedUsed, formattedTotal)
        level = switch percentage {
        case 0...74:
            .low
        case 75...99:
            .medium
        default:
            .full
        }
        self.shouldUpsell = shouldUpsell
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        HStack {
            Text(verbatim: "\(detail) (\(percentage)%)")
                .font(.callout)
                .fontWeight(level.textFontWeight)
                .foregroundStyle(level.textColor.toColor)

            switch level {
            case .low, .medium:
                CircularProgress(progress: CGFloat(percentage) / 100,
                                 lineWidth: 4,
                                 color: level.progressColor)
                    .fixedSize(horizontal: true, vertical: true)
            case .full:
                Image(uiImage: IconProvider.exclamationCircleFilled)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(level.progressColor.toColor)
                    .frame(maxHeight: 18)
            }
        }
        .if(shouldUpsell) { view in
            view.buttonEmbeded {
                if percentage >= 100 {
                    showUpsell.toggle()
                }
            }
        }
        .sheet(isPresented: $showUpsell) {
            StorageUpsell(detail: detail, onUpgrade: onUpgrade)
                .presentationDetents([.medium])
        }
    }
}

private struct StorageUpsell: View {
    @Environment(\.dismiss) private var dismiss

    let detail: String
    let onUpgrade: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            VStack(spacing: DesignConstant.sectionPadding) {
                Image(uiImage: PassIcon.storageFull)
                    .resizable()
                    .scaledToFit()
                    .padding(.top)

                Spacer()

                HStack {
                    Text(verbatim: detail)
                        .font(.headline)
                        .fontWeight(.medium)

                    Image(uiImage: IconProvider.exclamationCircleFilled)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)
                }
                .foregroundStyle(PassColor.signalDanger.toColor)

                Spacer()

                Text("Your storage is full.", bundle: .module)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PassColor.textNorm.toColor)

                Text("Upgrade to increase your storage capacity.", bundle: .module)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .multilineTextAlignment(.center)
                Spacer()

                CapsuleTextButton(title: #localized("Upgrade", bundle: .module),
                                  titleColor: PassColor.textInvert,
                                  backgroundColor: PassColor.interactionNormMajor1,
                                  action: onUpgrade)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding()

            Button(action: dismiss.callAsFunction) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .padding(4)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .padding(16)
            .buttonStyle(.plain)
        }
    }
}
