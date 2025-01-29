//
//
// LoginOnboardingView.swift
// Proton Pass - Created on 27/01/2025.
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

import DesignSystem
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct LoginOnboardingView: View {
    let onAction: () -> Void

    private struct CarouselItem {
        let title: String
        let subtitle: String
        let image: UIImage
        let secondaryImage: UIImage?

        init(title: String, subtitle: String, image: UIImage, secondaryImage: UIImage? = nil) {
            self.title = title
            self.subtitle = subtitle
            self.image = image
            self.secondaryImage = secondaryImage
        }
    }

    // Sample data for the carousel
    private let items: [CarouselItem] = [
        CarouselItem(title: "All your passwords.",
                     subtitle: "Securely in one place and protected by the most trusted name in privacy.",
                     image: PassIcon.firstLoginScreen,
                     secondaryImage: PassIcon.loginDeviceIcons),
        CarouselItem(title: "Protect your inbox.",
                     subtitle: "Use Hide-My-Email aliases against phishing threats.",
                     image: PassIcon.secondLoginScreen),
        CarouselItem(title: "Stay Informed.",
                     subtitle: "Get alerts when your email is found on the Dark web.",
                     image: PassIcon.thirdLoginScreen),
        CarouselItem(title: "Secure sharing.",
                     subtitle: "Share passwords and sensitive information securely and effortlessly.",
                     image: PassIcon.fourthLoginScreen)
    ]

    @State private var currentPage: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                pageIndicators

                carrousel
            }
            bottomActionButton
        }
        .background(RadialGradientView())
    }
}

private extension LoginOnboardingView {
    var pageIndicators: some View {
        // Page indicator at the top
        HStack(spacing: 8) {
            ForEach(0..<items.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(index == currentPage ? PassColor.textNorm.toColor : PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, maxHeight: 6)
            }
        }
        .animation(.default, value: currentPage)
        .padding(.top, 20)
        .padding(.horizontal, 36)
        .padding(.bottom, 50)
    }

    var carrousel: some View {
        TabView(selection: $currentPage) {
            ForEach(0..<items.count, id: \.self) { index in
                VStack(alignment: .center, spacing: 0) {
                    VStack(spacing: 8) {
                        Text(items[index].title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(PassColor.textNorm.toColor)
                        Text(items[index].subtitle)
                            .font(.title3)
                            .foregroundStyle(PassColor.textWeak.toColor)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 36)
                    Image(uiImage: items[index].image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)
                        .overlay {
                            if let secondaryImage = items[currentPage].secondaryImage {
                                VStack {
                                    Spacer()
                                    Spacer()
                                    Spacer()
                                    Image(uiImage: secondaryImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 177)
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                            }
                        }
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
    }

    var bottomActionButton: some View {
        VStack(spacing: 30) {
            CapsuleTextButton(title: #localized("Get Started"),
                              titleColor: PassColor.textNorm,
                              backgroundColor: PassColor.interactionNorm,
                              action: onAction)
                .padding(.horizontal, DesignConstant.sectionPadding)
            Image(uiImage: IconProvider.footer)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundStyle(PassColor.textNorm.toColor)
                .frame(height: 25)
        }
        .padding(.horizontal, 36)
    }
}

struct LoginOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        LoginOnboardingView(onAction: {})
    }
}

struct RadialGradientView: View {
    var body: some View {
        ZStack {
            Color(red: 0.12, green: 0.12, blue: 0.19) // #1F1F31
                .edgesIgnoringSafeArea(.all)

            RadialGradient(gradient: Gradient(stops: [
                .init(color: Color(red: 1.00, green: 0.84, blue: 0.50), location: 0.00),
                .init(color: Color(red: 0.96, green: 0.80, blue: 0.53), location: 0.0625),
                .init(color: Color(red: 0.89, green: 0.73, blue: 0.60), location: 0.1823),
                .init(color: Color(red: 0.82, green: 0.67, blue: 0.66), location: 0.2917),
                .init(color: Color(red: 0.79, green: 0.64, blue: 0.67), location: 0.3438),
                .init(color: Color(red: 0.73, green: 0.58, blue: 0.69), location: 0.4531),
                .init(color: Color(red: 0.60, green: 0.46, blue: 0.64), location: 0.5833),
                .init(color: Color(red: 0.45, green: 0.30, blue: 0.57), location: 0.7240),
                .init(color: Color(red: 0.19, green: 0.13, blue: 0.33), location: 0.8958),
                .init(color: Color(red: 0.11, green: 0.07, blue: 0.25), location: 1.00)
            ]),
            center: UnitPoint(x: 1.1, y: 1.1),
            startRadius: 0,
            endRadius: UIScreen.main.bounds
                .width * 1.5) /* max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 1.2896) */
                .edgesIgnoringSafeArea(.all)
        }
    }
}
