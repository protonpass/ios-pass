//
//  ScannedDocument.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation

public struct ScannedDocument: ScanResponse {
    public let scannedPages: [Page]

    public init(scannedPages: [Page]) {
        self.scannedPages = scannedPages
    }
}
