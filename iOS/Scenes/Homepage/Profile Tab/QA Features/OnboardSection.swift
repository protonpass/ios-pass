//
// OnboardSection.swift
// Proton Pass - Created on 15/04/2023.
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

struct OnboardSection: View {
    @State private var isShowingFullScreen = false
    @State private var isShowingSheet = false

    var body: some View {
        Section(content: {
            Button(action: {
                if UIDevice.current.isIpad {
                    isShowingSheet.toggle()
                } else {
                    isShowingFullScreen.toggle()
                }
            }, label: {
                Text(verbatim: "Onboard")
            })
        }, header: {
            Text(verbatim: "👋")
        })
        .fullScreenCover(isPresented: $isShowingFullScreen) { onboardingView }
        .sheet(isPresented: $isShowingSheet) { onboardingView }
    }

    @MainActor
    private var onboardingView: some View {
        OnboardingView(onWatchTutorial: {})
    }
}
