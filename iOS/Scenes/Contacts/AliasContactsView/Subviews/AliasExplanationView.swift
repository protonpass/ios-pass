//
// AliasExplanationView.swift
// Proton Pass - Created on 05/11/2024.
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

private enum ContactCreationSteps: Hashable {
    case first
    case second
    case third(email: String)

    var number: String {
        switch self {
        case .first: "1"
        case .second: "2"
        case .third: "3"
        }
    }

    var title: String {
        switch self {
        case .first:
            #localized("Enter the address you want to email.")
        case .second:
            #localized("Proton Pass will generate a forwarding address (also referred to as reverse alias).")
        case let .third(title):
            #localized("Email this address and it will appear to be sent from %@.", title)
        }
    }

    @MainActor @ViewBuilder
    var descriptionSubview: some View {
        switch self {
        case .first:
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.aliasInteractionNormMajor2,
                                 backgroundColor: PassColor.aliasInteractionNormMinor1,
                                 accessibilityLabel: "Close")
                    Spacer()

                    Text("Save")
                        .font(.callout)
                        .foregroundStyle(PassColor.textInvert.toColor)
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .background(PassColor.aliasInteractionNormMajor1.toColor)
                        .clipShape(Capsule())
                }
                Text("Create contact")
                    .font(.title.bold())
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .padding(.vertical, 16)

                Text(verbatim: "recipient_address@proton.me")
                    .padding(.top, 16)
                    .foregroundStyle(PassColor.textNorm.toColor)
            }
            .padding(16)
            .background(ZStack {
                PassColor.inputBorderNorm.toColor
                LinearGradient(gradient:
                    Gradient(colors: [
                        Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255, opacity: 0.05),
                        Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255, opacity: 0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing)
            })
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(PassColor.borderWeak.toColor, lineWidth: 1))
        case let .third(info):
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("From")
                                .fontWeight(.semibold)
                            Text("To")
                                .fontWeight(.semibold)
                        }.foregroundStyle(PassColor.textInvert.toColor)

                        VStack(alignment: .leading, spacing: 0) {
                            Label("From your alias <\(info)>",
                                  image: IconProvider.lockFilled)
                                .lineLimit(1)
                            Text("Your recipient")
                        }.foregroundStyle(PassColor.textInvert.toColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(uiImage: PassIcon.halfButtons)
                        .padding(.top, 16)
                }
                .padding(.leading, 18)
                .padding(.top, 12)
                .overlay(CustomBorderShape(cornerRadius: 12)
                    .stroke(PassColor.borderWeak.toColor, lineWidth: 1))
                .padding(.leading, 16)
                .padding(.top, 16)
                .frame(maxWidth: .infinity)
            }
            .background(.white)
            .cornerRadius(12)
        default:
            EmptyView()
        }
    }
}

struct AliasExplanationView: View {
    @Environment(\.dismiss) private var dismiss

    let email: String

    var body: some View {
        ScrollView {
            VStack {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: PassIcon.envelope)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .edgesIgnoringSafeArea(.all)

                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNorm,
                                 backgroundColor: PassColor.textNorm,
                                 accessibilityLabel: "Close",
                                 action: dismiss.callAsFunction)
                        .padding(16)
                }
                .frame(height: 178)
                .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Alias contacts")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(PassColor.textNorm.toColor)
                    // swiftlint:disable:next line_length
                    Text("To keep your personal email address hidden, you can create an alias contact that masks your address.")
                        .foregroundStyle(PassColor.textNorm.toColor)
                    Text("Here’s how it works:")
                        .foregroundStyle(PassColor.textNorm.toColor)

                    ForEach([
                        ContactCreationSteps.first,
                        ContactCreationSteps.second,
                        ContactCreationSteps.third(email: email)
                    ], id: \.self) { step in
                        ContactStepView(step: step)
                    }
                }.padding()

                Spacer()
            }.frame(maxWidth: .infinity)
        }.frame(maxWidth: .infinity)
    }
}

private struct ContactStepView: View {
    let step: ContactCreationSteps

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(step.number)
                    .foregroundStyle(PassColor.aliasInteractionNormMajor2.toColor)
                    .fontWeight(.medium)
                    .padding(10)
                    .background(Circle()
                        .stroke(PassColor.aliasInteractionNormMinor1.toColor, lineWidth: 1))
                VStack {
                    Divider()
                }
            }.padding(.top, 10)

            Text(step.title)
                .foregroundStyle(PassColor.textNorm.toColor)

            step.descriptionSubview
        }
    }
}

private struct CustomBorderShape: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start at top-left corner, but account for corner radius
        path.move(to: CGPoint(x: 0, y: cornerRadius))

        // Leading border
        path.addLine(to: CGPoint(x: 0, y: rect.height))

        // Back to top-left corner and create a curve for the top-left corner radius
        path.move(to: CGPoint(x: 0, y: cornerRadius))
        path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        // Top border
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        return path
    }
}
