//
//
// SecurityCenterView.swift
// Proton Pass - Created on 29/02/2024.
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

import DesignSystem
import Entities
import SwiftUI

enum SecureRowType {
    case info, warning, danger, success

    var icon: String? {
        switch self {
        case .danger, .warning:
            "exclamationmark.square.fill"
        case .success:
            "checkmark.square.fill"
        default:
            nil
        }
    }

    var iconColor: Color {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMajor1.toColor
        case .warning:
            PassColor.noteInteractionNormMajor1.toColor
        case .success:
            PassColor.cardInteractionNormMajor1.toColor
        default:
            .clear
        }
    }

    var background: UIColor {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMinor2
        case .warning:
            PassColor.noteInteractionNormMinor2
        case .success:
            PassColor.cardInteractionNormMinor2
        case .info:
            PassColor.backgroundNorm
        }
    }

    var border: UIColor {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMinor1
        case .warning:
            PassColor.noteInteractionNormMinor1
        case .success:
            PassColor.cardInteractionNormMinor1
        case .info:
            PassColor.inputBorderNorm
        }
    }

    var infoForeground: Color {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMajor2.toColor
        case .warning:
            PassColor.noteInteractionNormMajor2.toColor
        case .success:
            PassColor.cardInteractionNormMajor2.toColor
        case .info:
            PassColor.textNorm.toColor
        }
    }

    var infoBackground: Color {
        switch self {
        case .danger:
            PassColor.passwordInteractionNormMinor1.toColor
        case .warning:
            PassColor.noteInteractionNormMinor1.toColor
        case .success:
            PassColor.cardInteractionNormMinor1.toColor
        case .info:
            PassColor.backgroundMedium.toColor
        }
    }

//    var icon: String? {
//        switch self {
//        case .danger:
//        case .info:
//        case .warning:
//        case .success:
//
//        default:
//            return nil
//        }
//    }
}

struct SecurityCenterView: View {
    @StateObject var viewModel: SecurityCenterViewModel

    private enum ElementSizes {
        static let circleSize: CGFloat = 15
        static let line: CGFloat = 1
        static let cellHeight: CGFloat = 75

        static var minSpacerSize: CGFloat {
            (ElementSizes.cellHeight - ElementSizes.circleSize / 2) / 2
        }
    }

    var body: some View {
//            ScrollView {

        mainContent
            .animation(.default, value: viewModel.weakPasswordsLogins)
            .padding(.horizontal, DesignConstant.sectionPadding)
            .navigationTitle("Security Center")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .showSpinner(viewModel.loading)
            .navigationStackEmbeded()
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .navigationTitle("Security Center")
//            .navigationBarTitleDisplayMode(.large)
//            .background(PassColor.backgroundNorm.toColor)
    }
}

//    .animation(.default, value: viewModel.history)
//    .padding(.horizontal, DesignConstant.sectionPadding)
//    .navigationTitle("History")
//    .toolbar { toolbarContent }
//    .scrollViewEmbeded(maxWidth: .infinity)
//    .background(PassColor.backgroundNorm.toColor)
//    .showSpinner(viewModel.loading)
//    .routingProvided
//    .navigationStackEmbeded($path)

private extension SecurityCenterView {
    var mainContent: some View {
        VStack {
            if let weakPasswords = viewModel.weakPasswordsLogins {
                warningRow(rowType: .warning, title: "test", subTitle: "test", info: "9")
                warningRow(rowType: .danger, title: "test", subTitle: "test", info: "9")
                warningRow(rowType: .success, title: "test", subTitle: "test", info: "9")
                warningRow(rowType: .info, title: "test", subTitle: "test", info: "9")
//
//                dangerRow()
//                successRow()
//                infoRow()
            }
            Spacer()
        }
    }
}

// MARK: - Rows

private extension SecurityCenterView {
    func warningRow(rowType: SecureRowType, title: String, subTitle: String, info: String) -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            if let iconName = rowType.icon {
                Image(systemName: iconName)
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(rowType.iconColor)
                    .frame(width: 20)
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text(subTitle)
                    .font(.footnote)
                    .foregroundColor(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
            .contentShape(Rectangle())

            Text(info)
                .padding(.vertical, 4)
                .padding(.horizontal, 11) // Add padding around the text to ensure the capsule has space
                .foregroundColor(rowType.infoForeground) // Set text color
                .background(rowType.infoBackground) // Set the background color of the capsule
                .clipShape(Capsule())
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .roundedDetailSection(backgroundColor: rowType.background,
                              borderColor: rowType.border)
    }

    func dangerRow() -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            Image(systemName: "exclamationmark.square.fill")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(PassColor.passwordInteractionNormMajor1.toColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Warning")
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text("subwarning")
                    .font(.footnote)
                    .foregroundColor(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
            .contentShape(Rectangle())

            Text("9")
                .padding(.vertical, 4)
                .padding(.horizontal, 11) // Add padding around the text to ensure the capsule has space
                .foregroundColor(PassColor.passwordInteractionNormMajor2.toColor) // Set text color
                .background(PassColor.passwordInteractionNormMinor1
                    .toColor) // Set the background color of the capsule
                .clipShape(Capsule())
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .roundedDetailSection(backgroundColor: PassColor.passwordInteractionNormMinor2,
                              borderColor: PassColor.passwordInteractionNormMinor1)
    }

    func successRow() -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            Image(systemName: "exclamationmark.square.fill")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(PassColor.cardInteractionNormMajor1.toColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Warning")
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text("subwarning")
                    .font(.footnote)
                    .foregroundColor(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
            .contentShape(Rectangle())

            Text("9")
                .padding(.vertical, 4)
                .padding(.horizontal, 11) // Add padding around the text to ensure the capsule has space
                .foregroundColor(PassColor.cardInteractionNormMajor2.toColor) // Set text color
                .background(PassColor.cardInteractionNormMinor1.toColor) // Set the background color of the capsule
                .clipShape(Capsule())
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .roundedDetailSection(borderColor: PassColor.cardInteractionNormMinor1)
    }

    func infoRow() -> some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Warning")
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Text("subwarning")
                    .font(.footnote)
                    .foregroundColor(PassColor.textWeak.toColor)
            }
            .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
            .contentShape(Rectangle())

            Text("9")
                .padding(.vertical, 4)
                .padding(.horizontal, 11) // Add padding around the text to ensure the capsule has space
                .foregroundColor(PassColor.textNorm.toColor) // Set text color
                .background(PassColor.backgroundMedium.toColor) // Set the background color of the capsule
                .clipShape(Capsule())
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .roundedDetailSection(backgroundColor: PassColor.backgroundNorm,
                              borderColor: PassColor.inputBorderNorm)
    }
}

// var color: Color {
//    switch self {
//    case .vulnerable:
//        PassColor.signalDanger.toColor
//    case .weak:
//        PassColor.signalWarning.toColor
//    case .strong:
//        PassColor.signalSuccess.toColor
//    }
// }

// func infoRow(title: LocalizedStringKey,
//             infos: String?,
//             icon: UIImage,
//             shouldDisplay: Bool = true) -> some View {
//    HStack(spacing: DesignConstant.sectionPadding) {
//        ItemDetailSectionIcon(icon: icon,
//                              color: PassColor.textWeak)
//
//        VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
//            Text(title)
//                .font(.body)
//                .foregroundStyle(PassColor.textNorm.toColor)
//            if let infos {
//                Text(infos)
//                    .font(.footnote)
//                    .foregroundColor(PassColor.textWeak.toColor)
//            }
//        }
//        .frame(maxWidth: .infinity, minHeight: ElementSizes.cellHeight, alignment: .leading)
//        .contentShape(Rectangle())
//        if shouldDisplay {
//            ItemDetailSectionIcon(icon: IconProvider.chevronRight,
//                                  color: PassColor.textWeak)
//        }
//    }
//    .padding(.horizontal, DesignConstant.sectionPadding)
//    .roundedDetailSection()
// }

// struct MainSecurityCenterView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainSecurityCenterView()
//    }
// }
