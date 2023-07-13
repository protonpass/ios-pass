//
//  Mailbox.swift
//
//
//  Created by martin on 13/07/2023.
//

public struct Mailbox: Decodable, Hashable, Equatable {
    // Should not rename to "id" otherwise decode process breaks
    public let ID: Int
    public let email: String
}
