//
//
// AuthenticatorView.swift
// Proton Pass - Created on 15/03/2024.
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

import Client
import DesignSystem
import Entities
import SwiftUI

enum AlbumSorting: String, CaseIterable, Identifiable {
    case title
    case recentlyAdded
    case artist
    var id: Self { self }

    var title: String {
        switch self {
        case .title:
            "Title"
        case .recentlyAdded:
            "Recently Added"
        case .artist:
            "Artist"
        }
    }
}

struct AuthenticatorView: View {
    @StateObject private var viewModel = AuthenticatorViewModel()
    @State private var selectedSorting = AlbumSorting.artist

    var body: some View {
        mainContent
            .animation(.default, value: viewModel.displayedItems)
            .navigationTitle("Authenticator")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
//                    Menu(content: {
//                        Text("Menu Item 1")
//                        Text("Menu Item 2")
//                        Text("Menu Item 3")
//                    }, label: { Text("button") })

                    Menu {
                        Picker("Sort", selection: $selectedSorting) {
                            ForEach(AlbumSorting.allCases) {
                                Text($0.title)
                            }
                        }
                    } label: {
                        Text("Sort")
                    }
                }
            }
            .navigationStackEmbeded()

//            .toolbar {
//                ToolbarItem {
//                    Menu {
//                        Section("Primary Actions") {
//                            Button("First") {}
//                            Button("Second") {}
//                        }
//
//                        Button {
//                            // Add this item to a list of favorites.
//                        } label: {
//                            Label("Add to Favorites", systemImage: "heart")
//                        }
//
//                        Divider()
//
//                        Button(role: .destructive) {} label: {
//                            Label("Delete", systemImage: "trash")
//                        }
//                    } label: {
//                        Label("Menu", systemImage: "ellipsis.circle")
//                    }
//                }
//            }
            .searchable(text: $viewModel.searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Look for something")
            .task {
                await viewModel.load()
            }
    }
}

private extension AuthenticatorView {
    var mainContent: some View {
        LazyVStack {
            itemsList(items: viewModel.displayedItems)
        }
        .padding(DesignConstant.sectionPadding)
//        .listStyle(.plain)
    }

    func itemsList(items: [ItemContent]) -> some View {
        ForEach(items) { item in
            itemRow(for: item)
                .roundedEditableSection()
        }
    }

    func itemRow(for item: ItemContent) -> some View {
//        GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
//                       title: item.title,
//                       description: item.toItemUiModel.description)
//            .frame(maxWidth: .infinity, alignment: .leading)

        AuthenticatorRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData(), size: .large) },
                         uri: item.loginItem?.totpUri ?? "",
                         title: "\(item.name)",
                         onCopyTotpToken: { _ in })
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AuthenticatorView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatorView()
    }
}

// TOTPRow(totpManager: viewModel.totpManager,
//        textColor: textColor(for: \.loginItem?.totpUri),
//        tintColor: PassColor.loginInteractionNorm,
//        onCopyTotpToken: { viewModel.copyTotpToken($0) })

// totpManager.bind(uri: totpUri)

import Core
import DesignSystem
import Factory
import ProtonCoreUIFoundations
import SwiftUI

struct AuthenticatorRow<ThumbnailView: View>: View {
    @ObservedObject private var totpManager = resolve(\ServiceContainer.totpManager)
//    @State private var totpManager = resolve(\ServiceContainer.totpManager)
    private let thumbnailView: ThumbnailView
    private let uri: String
    private let title: String
    private let onCopyTotpToken: (String) -> Void

    init(@ViewBuilder thumbnailView: () -> ThumbnailView,
         uri: String,
         title: String,
         onCopyTotpToken: @escaping (String) -> Void) {
        self.onCopyTotpToken = onCopyTotpToken
        self.uri = uri
        self.thumbnailView = thumbnailView()
        self.title = title
        totpManager.bind(uri: uri)
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            VStack {
                Spacer()
                thumbnailView
                    .frame(width: 60)
                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(PassColor.textWeak.toColor)
                switch totpManager.state {
                case .empty:
                    TOTPText(code: "", textColor: PassColor.textNorm, font: .title)
                        .frame(maxWidth: .infinity, alignment: .leading)

                //                    EmptyView()
                case .loading:
                    ProgressView()
                case let .valid(data):
                    TOTPText(code: data.code, textColor: PassColor.textNorm, font: .title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .invalid:
                    Text("Invalid TOTP URI")
                        .font(.caption)
                        .foregroundStyle(PassColor.signalDanger.toColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if let data = totpManager.totpData {
                    onCopyTotpToken(data.code)
                }
            }
//            RingAnimation()
//            CountdownTimerView()
            switch totpManager.state {
            case let .valid(data):
                TOTPCircularTimer(data: data.timerData)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .padding(.horizontal)
//        .animation(.default, value: totpManager.state)
    }
}

import PassRustCore

// struct CountdownTimerView: View {
////    // Countdown duration
////    let duration: TimeInterval = 10
////
////    // Current countdown value
////    @State private var currentTime = 10.0
////
////    // Progress of the countdown for the circular progress view
////    @State private var progress = 1.0
////
////    @State private var timer: Timer?
////
////    var body: some View {
////        ZStack {
////            // Circular Progress Bar
////            Circle()
////                .trim(from: 0, to: progress)
////                .stroke(lineWidth: 2)
////                .rotation(.degrees(-90)) // Start from the top
////                .animation(.linear(duration: duration).repeatForever(autoreverses: false), value: progress)
//    ////                .onAppear {
//    ////                    progress = 0
//    ////                }
////
////            // Countdown Number
////            Text("\(Int(currentTime))")
////                .font(.caption)
////                .fontWeight(.light)
//    ////                .onAppear {
//    ////            startTimer()
//    ////        }
//    ////                .onAppear {
//    ////                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//    ////                        if currentTime > 0 {
//    ////                            currentTime -= 1
//    ////                        } else {
//    ////                            currentTime = duration
//    ////                            progress = 1
//    ////                        }
//    ////                    }
//    ////                }
////        }
////        .frame(width: 40, height: 40)
////
//    ////        .frame(width: 200, height: 200)
////        .padding()
////        .onAppear {
////            startTimer()
////        }
////        .onDisappear {
////            stopTimer()
////        }
////    }
////
////    private func startTimer() {
//    ////        currentTime = duration // Reset the time
//    ////        progress = 1 // Reset progress for a new animation cycle
////
////        // Invalidate the existing timer if it exists
////        timer?.invalidate()
////
////        // Create a new timer
////        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
////            if currentTime > 0 {
////                currentTime -= 1
////            } else {
////                currentTime = duration
////                progress = 1
////            }
////        }
////    }
////
////    private func stopTimer() {
////        timer?.invalidate() // Stop the timer
////        timer = nil // Clear the timer
////    }
//
////    // Countdown duration
////    let duration: TimeInterval = 10
////
////    // Current countdown value
////    @State private var currentTime: TimeInterval
////
////    // Progress of the countdown for the circular progress view
////    @State private var progress: CGFloat
////
////    // Timer
////    @State private var timer: Timer?
////
////    init() {
////        _currentTime = State(initialValue: duration)
////        _progress = State(initialValue: 1)
////    }
////
////    var body: some View {
////        ZStack {
////            Circle()
////                .stroke(lineWidth: 2)
////                .opacity(0.3)
////                .foregroundColor(.gray)
////
////            Circle()
////                .trim(from: 0, to: progress)
////                .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
////                .foregroundColor(.blue)
////                .rotationEffect(Angle(degrees: -90))
////                .animation(.linear(duration: duration), value: progress)
////
////            Text("\(Int(currentTime))")
////                .font(.largeTitle)
////        }
////        .frame(width: 40, height: 40)
////        .padding()
////        .onAppear {
////            startTimer()
////        }
////        .onDisappear {
////            stopTimer()
////        }
////    }
//
//    private func startTimer() {
//        timer?.invalidate() // Invalidate existing timer
//
//        currentTime = duration // Reset time
//        progress = 1 // Ensure progress starts full for animation
//
//        // Delayed reset to ensure progress animation restarts properly
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            progress = 0 // Restart progress animation
//        }
//
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//            if currentTime > 0 {
//                currentTime -= 1
////                withAnimation {
////                    progress = CGFloat(currentTime / duration)
////                }
//            } else {
//                currentTime = duration
//                progress = 1
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    progress = 0 // Reset for next cycle
//                }
//            }
//        }
//    }
//
//    private func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
// }

struct CountdownTimerView: View {
    let duration: TimeInterval = 10

    @State private var currentTime: TimeInterval
    @State private var progress: CGFloat = 1.0
    @State private var isActive: Bool = false
    @State var appear = false

    init() {
        _currentTime = State(initialValue: duration)
    }

    var body: some View {
        VStack {
            ZStack {
//                Circle()
//                    .stroke(lineWidth: 20)
//                    .opacity(0.3)
//                    .foregroundColor(.gray)
//
//                Circle()
//                    .trim(from: 0, to: progress)
//                    .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
//                    .foregroundColor(.blue)
//                    .rotationEffect(Angle(degrees: -90))
//                    .animation(isActive ? Animation.linear(duration: duration)
//                        .repeatForever(autoreverses: false) : .default,
//                        value: isActive)

                Text("\(Int(currentTime))")
                    .font(.largeTitle)
            }
            .frame(width: 200, height: 200)
            .padding()
//            .onAppear {
//                startTimer()
//            }
        }
    }

    func startTimer() {
        // Reset states for the timer and progress
        currentTime = duration
        progress = 1.0
        isActive = false

        // Delay to ensure the animation restarts smoothly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isActive = true
            withAnimation {
                progress = 0
            }
        }

        // Define the timer
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if currentTime > 0 {
                currentTime -= 1
            } else {
                // Reset for next cycle
                currentTime = duration
                isActive = false
                progress = 1.0

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isActive = true
                    withAnimation {
                        progress = 0
                    }
                }
            }
        }
    }
}

struct RingAnimation: View {
    @State private var drawingStroke = false

    let strawberry = Color(#colorLiteral(red: 1, green: 0.1857388616, blue: 0.5733950138, alpha: 1))
    let lime = Color(#colorLiteral(red: 0.5563425422, green: 0.9793455005, blue: 0, alpha: 1))
    let ice = Color(#colorLiteral(red: 0.4513868093, green: 0.9930960536, blue: 1, alpha: 1))

    let animation = Animation
        .linear(duration: 3)
        .repeatForever(autoreverses: false)
//        .delay(0.5)

    var body: some View {
        ZStack {
            Color.black
            ring(for: strawberry)
                .frame(width: 40)
//            ring(for: lime)
//                .frame(width: 128)
//            ring(for: ice)
//                .frame(width: 92)
        }
        .animation(animation, value: drawingStroke)
        .onAppear {
            drawingStroke.toggle()
        }
    }

    func ring(for color: Color) -> some View {
        // Background ring
        Circle()
            .stroke(style: StrokeStyle(lineWidth: 2))
            .foregroundStyle(.tertiary)
            .overlay {
                // Foreground ring
                Circle()
                    .trim(from: 0, to: drawingStroke ? 1 : 0)
                    .stroke(color.gradient,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
//            .rotationEffect(.degrees(-90))
    }
}
