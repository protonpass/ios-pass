//
// Shimmer.swift
// Proton Pass - Created on 11/12/2023.
// Copyright (c) 2023 Proton Technologies AG
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

// swiftlint:disable void_function_in_ternary
/// A view modifier that applies an animated "shimmer" to any view
public struct Shimmer: ViewModifier {
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var isInitialState = true
    private let animation: Animation
    private let gradient: Gradient
    private let min, max: CGFloat

    /// Initializes this modifier with a custom animation,
    /// - Parameters:
    ///   - animation: A custom animation
    ///   - gradient: A custom gradient
    ///   - bandSize: The size of the animated mask's "band"
    public init(animation: Animation = Self.defaultAnimation,
                gradient: Gradient = Self.defaultGradient,
                bandSize: CGFloat = Self.defaultBandSize) {
        self.animation = animation
        self.gradient = gradient
        // Calculate unit point dimensions beyond the gradient's edges by the band size
        self.min = 0 - bandSize
        self.max = 1 + bandSize
    }

    /// The start unit point of our gradient, adjusting for layout direction.
    var startPoint: UnitPoint {
        if layoutDirection == .rightToLeft {
            isInitialState ? UnitPoint(x: max, y: min) : UnitPoint(x: 0.5, y: 1)
        } else {
            isInitialState ? UnitPoint(x: min, y: min) : UnitPoint(x: 1, y: 0.5)
        }
    }

    /// The end unit point of our gradient, adjusting for layout direction.
    var endPoint: UnitPoint {
        if layoutDirection == .rightToLeft {
            isInitialState ? UnitPoint(x: 1, y: 0.5) : UnitPoint(x: min, y: max)
        } else {
            isInitialState ? UnitPoint(x: 0, y: 0.5) : UnitPoint(x: max, y: max)
        }
    }

    public func body(content: Content) -> some View {
        content
            .mask(LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint))
            .animation(animation, value: isInitialState)
            .onAppear {
                isInitialState = false
            }
    }
}

public extension Shimmer {
    static let defaultAnimation = Animation
        .linear(duration: 1).delay(0)
        .repeatForever(autoreverses: false)

    static let defaultGradient = Gradient(colors: [
        .black.opacity(0.3),
        .black,
        .black.opacity(0.3)
    ])

    static let defaultBandSize: CGFloat = 0.5
}

public extension View {
    @ViewBuilder
    func shimmering(active: Bool = true,
                    animation: Animation = Shimmer.defaultAnimation,
                    gradient: Gradient = Shimmer.defaultGradient,
                    bandSize: CGFloat = Shimmer.defaultBandSize) -> some View {
        if active {
            modifier(Shimmer(animation: animation, gradient: gradient, bandSize: bandSize))
        } else {
            self
        }
    }
}

// swiftlint:enable void_function_in_ternary
