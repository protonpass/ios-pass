//
// InAppModalView.swift
// Proton Pass - Created on 07/11/2024.
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
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct InAppModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0

    @StateObject private var viewModel: InAppModalViewModel
    private let notification: InAppNotification
    private let borderColor: UIColor = PassColor.inputBorderNorm
    private let onTap: (InAppNotification) -> Void
    private let onClose: (InAppNotification) -> Void

    public init(notification: InAppNotification,
                viewModel: InAppModalViewModel,
                onTap: @escaping (InAppNotification) -> Void,
                onClose: @escaping (InAppNotification) -> Void) {
        _viewModel = .init(wrappedValue: viewModel)
        self.notification = notification
        self.onTap = onTap
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            PassColor.backgroundWeak.toColor
            VStack(spacing: 24) {
                if let imageUrl = notification.content.safeImageUrl {
                    AsyncImage(url: imageUrl,
                               content: { image in
                                   image.resizable()
                                       .aspectRatio(contentMode: .fit)
                                       .frame(minHeight: 150, idealHeight: 180, maxHeight: 180)
                                       .background(GeometryReader { proxy in
                                           Color.clear
                                               .onAppear {
                                                   contentHeight += proxy.size.height
                                               }
                                       })
                               },
                               placeholder: {
                                   ProgressView()
                               })
                }

                Text(verbatim: notification.content.title)
                    .font(.title.weight(.medium))
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(verbatim: notification.content.message)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity,
                           alignment: notification.content.safeImageUrl == nil ? .center : .top)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)

                if let cta = notification.content.cta {
                    CapsuleTextButton(title: cta.text,
                                      titleColor: PassColor.textInvert,
                                      backgroundColor: PassColor.interactionNormMajor2,
                                      height: 48,
                                      action: {
                                          dismiss()
                                          onTap(notification)
                                      })
                                      .padding(.horizontal, DesignConstant.sectionPadding)
                }
            }
            .padding(DesignConstant.sectionPadding)
            .background(PassColor.backgroundWeak.toColor)
            .frame(maxWidth: .infinity)
            .background(GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        contentHeight += proxy.size.height
                    }
            })

            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.backgroundNorm,
                         backgroundColor: PassColor.textNorm,
                         accessibilityLabel: "Close",
                         type: .custom(buttonSize: 30, iconSize: 25),
                         action: {
                             dismiss()
                             onClose(notification)
                         })
                         .padding()
        }
        .frame(maxWidth: .infinity)
        .interactiveDismissDisabled()
        .onChange(of: contentHeight) { value in
            viewModel.updateSheetHeight(value)
        }
    }
}

@MainActor
public final class InAppModalViewModel: ObservableObject {
    public weak var sheetPresentation: UISheetPresentationController?

    public init() {}

    func updateSheetHeight(_ height: CGFloat) {
        guard let sheetPresentation else {
            return
        }
        let custom = UISheetPresentationController.Detent.custom { _ in
            CGFloat(height)
        }
        sheetPresentation.animateChanges {
            sheetPresentation.detents = [custom]
        }
    }
}
