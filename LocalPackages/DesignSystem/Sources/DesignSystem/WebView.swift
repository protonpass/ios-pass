//
// WebView.swift
// Proton Pass - Created on 18/01/2024.
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

// periphery:ignore:all
import SwiftUI
import WebKit

public extension WKWebViewConfiguration {
    static var nonPersistent: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        return config
    }
}

public struct WebView: UIViewRepresentable {
    private let url: URL
    private let configuration: WKWebViewConfiguration

    public init(url: URL, configuration: WKWebViewConfiguration = .nonPersistent) {
        self.url = url
        self.configuration = configuration
    }

    public func makeUIView(context: Context) -> WKWebView {
        WKWebView(frame: .zero, configuration: configuration)
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
