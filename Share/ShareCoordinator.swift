//
// ShareCoordinator.swift
// Proton Pass - Created on 22/01/2024.
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

import Core
import DesignSystem
import SwiftUI
import UIKit

enum SharedContent {
    case url(URL)
    case text(String)
    case textWithUrl(String, URL)
    case unknown
}

enum SharedItemType: CaseIterable {
    case note, login
}

@MainActor
final class ShareCoordinator {
    private var lastChildViewController: UIViewController?
    private weak var rootViewController: UIViewController?

    private var context: NSExtensionContext? { rootViewController?.extensionContext }

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
}

extension ShareCoordinator {
    func start() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let content = try await parseSharedContent()
                let view = SharedContentView(content: content,
                                             onCreate: { [weak self] type in
                                                 guard let self else { return }
                                                 presentCreateItemView(for: type, content: content)
                                             },
                                             onDismiss: { [weak self] in
                                                 guard let self else { return }
                                                 dismissExtension()
                                             })
                showView(view)
            } catch {
                alert(error: error) { [weak self] in
                    guard let self else { return }
                    dismissExtension()
                }
            }
        }
    }

    func presentCreateItemView(for type: SharedItemType, content: SharedContent) {
        print(type)
    }

    func dismissExtension() {
        context?.completeRequest(returningItems: nil)
    }
}

extension ShareCoordinator: ExtensionCoordinator {
    func getRootViewController() -> UIViewController? {
        rootViewController
    }

    func getLastChildViewController() -> UIViewController? {
        lastChildViewController
    }

    func setLastChildViewController(_ viewController: UIViewController) {
        lastChildViewController = viewController
    }
}

private extension ShareCoordinator {
    func parseSharedContent() async throws -> SharedContent {
        guard let extensionItems = context?.inputItems as? [NSExtensionItem] else {
            assertionFailure("Failed to cast inputItems into NSExtensionItems")
            return .unknown
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for attachment in attachments {
                // Optionally parse URL and fallback to text
                if let url = try? await attachment.loadItem(forTypeIdentifier: "public.url") as? URL {
                    return .url(url)
                }

                if let text = try await attachment.loadItem(forTypeIdentifier: "public.text") as? String {
                    if let url = text.firstUrl() {
                        return .textWithUrl(text, url)
                    } else {
                        return .text(text)
                    }
                }
            }
        }

        return .unknown
    }
}
