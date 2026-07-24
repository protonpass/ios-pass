//
// DeepLinkRouter.swift
// Proton Pass - Created on 16/07/2026.
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

import Core
import CoreSpotlight
import Foundation
import UIKit
import UseCases

enum DeeplinkType {
    case otpauth
    case unknown
}

extension URL {
    var linkType: DeeplinkType {
        if scheme == "otpauth" {
            return .otpauth
        }
        return .unknown
    }
}

@MainActor
public protocol DeepLinkRouterProtocol: Sendable {
    func parseAndDispatch(context: Set<UIOpenURLContext>)
    func handle(userActivities: Set<NSUserActivity>)
}

@MainActor
struct DeepLinkRouter: DeepLinkRouterProtocol {
    private let router: any UIKitSwiftUIBridgeRouterProtocol
    private let getItemContentFromBase64IDs: any GetItemContentFromBase64IDsUseCase

    init(router: any UIKitSwiftUIBridgeRouterProtocol,
         getItemContentFromBase64IDs: any GetItemContentFromBase64IDsUseCase) {
        self.router = router
        self.getItemContentFromBase64IDs = getItemContentFromBase64IDs
    }

    func parseAndDispatch(context: Set<UIOpenURLContext>) {
        guard let url = context.first?.url else {
            return
        }
        switch url.linkType {
        case .otpauth:
            let uri = url.absoluteString.decodeHTMLAndPercentEntities()
            guard !uri.isEmpty else {
                return
            }
            router.requestDeeplink(.totp(uri))

        default:
            return
        }
    }

    func handle(userActivities: Set<NSUserActivity>) {
        for activity in userActivities {
            switch activity.activityType {
            case CSSearchableItemActionType:
                if let base64Ids = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                    Task {
                        do {
                            let itemContent = try await getItemContentFromBase64IDs(for: base64Ids)
                            router.requestDeeplink(.spotlightItemDetail(itemContent))
                        } catch {
                            router.requestDeeplink(.error(error))
                        }
                    }
                }

            default:
                break
            }
        }
    }
}
