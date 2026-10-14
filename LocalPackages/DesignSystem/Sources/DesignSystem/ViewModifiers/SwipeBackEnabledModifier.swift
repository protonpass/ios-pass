//
// SwipeBackEnabledModifier.swift
// Proton Pass - Created on 06/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import UIKit

public extension View {
    /// Restores the edge swipe back gesture of the enclosing `NavigationStack`, which SwiftUI disables
    /// as soon as a pushed view hides the system back button. Apply once on the stack's root view.
    func swipeBackEnabled() -> some View {
        background(SwipeBackEnabler())
    }
}

private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> SwipeBackEnablerViewController {
        .init()
    }

    func updateUIViewController(_ uiViewController: SwipeBackEnablerViewController, context: Context) {}
}

/// The gesture's delegate is weak, this controller lives as long as the stack's root view which is never popped
private final class SwipeBackEnablerViewController: UIViewController, UIGestureRecognizerDelegate {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController else { return false }
        // Swiping while a push is still animating leaves the stack frozen
        return navigationController.viewControllers.count > 1
            && navigationController.transitionCoordinator == nil
    }
}
