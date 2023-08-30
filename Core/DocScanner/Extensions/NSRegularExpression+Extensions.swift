//
//  NSRegularExpression+Extensions.swift
//  DocScannerDemo
//
//  Created by martin on 27/08/2023.
//

import Foundation

extension NSRegularExpression {
    func matches(in content: String) -> [NSTextCheckingResult] {
        matches(in: content, range: content.fullRange)
    }
}
