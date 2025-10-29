//
// SectionIndexTitles.swift
// Proton Pass - Created on 12/03/2023.
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

import Client
import DesignSystem
import Entities
import SwiftUI

// https://www.fivestars.blog/articles/section-title-index-swiftui/
struct SectionIndexTitles: View {
    let proxy: ScrollViewProxy
    let direction: SortDirection
    @GestureState private var dragLocation: CGPoint = .zero
    @State private var lastScrolledToTitle: String?

    var body: some View {
        VStack {
            ForEach(AlphabetLetter.letters(for: direction), id: \.rawValue) { letter in
                Text(letter.character)
                    .font(.caption)
                    .foregroundStyle(PassColor.interactionNorm)
                    .multilineTextAlignment(.trailing)
                    .padding(.leading)
                    .contentShape(.rect)
                    .background(dragObserver(title: letter.character))
            }
        }
        .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($dragLocation) { value, state, _ in
                state = value.location
            })
    }

    func dragObserver(title: String) -> some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).contains(dragLocation) {
                // we need to dispatch to the main queue because we cannot access to the
                // `ScrollViewProxy` instance while the body is rendering
                if title != lastScrolledToTitle {
                    DispatchQueue.main.async {
                        lastScrolledToTitle = title
                        UISelectionFeedbackGenerator().selectionChanged()
                        proxy.scrollTo(title, anchor: .center)
                    }
                }
            }
            return Color.clear
        }
    }
}
