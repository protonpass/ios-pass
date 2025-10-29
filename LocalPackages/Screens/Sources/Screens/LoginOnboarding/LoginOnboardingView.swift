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

public struct LoginOnboardingView: View {
    @State private var currentPage: Int = 0

    private let onAction: (Bool) -> Void

    public init(onAction: @escaping (_ signUp: Bool) -> Void) {
        self.onAction = onAction
    }

    private struct CarouselItem {
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
        let image: Image
        let secondaryImage: Image?

        init(title: LocalizedStringKey,
             subtitle: LocalizedStringKey,
             image: Image,
             secondaryImage: Image? = nil) {
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

    public var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                pageIndicators
                    .padding(.horizontal, 36)

                carrousel(proxy)

                Group {
                    bottomActionButton(signUp: true)
                    bottomActionButton(signUp: false)
                        .padding(.vertical, 8)
                    IconProvider.footer
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(height: 20)
                        .padding(.vertical)
                }
                .padding(.horizontal, 36)
            }
            .padding(.top, 20)
            .background(RadialGradientView())
        }
    }
}

private extension LoginOnboardingView {
    var pageIndicators: some View {
        // Page indicator at the top
        HStack(spacing: 8) {
            ForEach(0..<items.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white)
                    .frame(maxWidth: .infinity, maxHeight: 6)
                    .opacity(index == currentPage ? 1 : 0.1)
            }
        }
        .animation(.default, value: currentPage)
    }

    func carrousel(_ proxy: GeometryProxy) -> some View {
        TabView(selection: $currentPage) {
            ForEach(0..<items.count, id: \.self) { index in
                VStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: proxy.size.height > 800 ? proxy.size.height / 10 : 16)

                    VStack(spacing: 8) {
                        Text(items[index].title, bundle: .module)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(items[index].subtitle, bundle: .module)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 36)
                    Spacer()
                    items[index].image
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
                                    Spacer()
                                    secondaryImage
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 177)
                                        .foregroundStyle(.white)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.vertical, -proxy.size.height / 14)
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentPage)
    }

    @ViewBuilder
    func bottomActionButton(signUp: Bool) -> some View {
        if signUp {
            CapsuleTextButton(title: #localized("Create an account", bundle: .module),
                              titleColor: .white,
                              backgroundColor: signUp ? Color(red: 110, green: 74, blue: 255) : .clear,
                              action: { onAction(signUp) })
        } else {
            CapsuleTextBorderedButton(title: #localized("Sign in", bundle: .module),
                                      titleColor: .white,
                                      borderColor: .white,
                                      borderWidth: 1,
                                      action: { onAction(signUp) })
        }
    }
}

// periphery:ignore
// swiftlint:disable:next discouraged_previewprovider
struct LoginOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        LoginOnboardingView(onAction: { _ in })
    }
}

private struct RadialGradientView: View {
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
            endRadius: UIScreen.main.bounds.width * 1.5)
                .edgesIgnoringSafeArea(.all)
        }
    }
}
