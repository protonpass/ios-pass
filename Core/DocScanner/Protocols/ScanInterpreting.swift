//
//  ScanInterpreting.swift
//
//
//  Created by Martin Lukacs on 24/08/2023.
//

import Foundation
import VisionKit

public protocol ScanInterpreting: Actor {
    func parseAndInterpret(scans: VNDocumentCameraScan) async -> ScanResponse
}
