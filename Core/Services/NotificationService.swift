//
// NotificationService.swift
// Proton Pass - Created on 06/06/2023.
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

import Foundation
import UserNotifications

public protocol LocalNotificationServiceProtocol {
    func requestNotificationPermission(with options: UNAuthorizationOptions)
    
    func add(for request: UNNotificationRequest)
    func addWithTimer(for request: UNNotificationRequest, and delay: TimeInterval)
}

public extension LocalNotificationServiceProtocol {
    func requestNotificationPermission(with options: UNAuthorizationOptions = [.alert]) {
        requestNotificationPermission(with: options)
    }
}

public final class NotificationService: LocalNotificationServiceProtocol {
    private let unUserNotificationCenter: UNUserNotificationCenter
    private var currentTimers: [String: Timer] = [:]
    private let logger: Logger
    
    public init(logger: Logger,
                unUserNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.unUserNotificationCenter = unUserNotificationCenter
        self.logger = logger
    }
    
    public func requestNotificationPermission(with options: UNAuthorizationOptions = []) {
        unUserNotificationCenter.requestAuthorization(options: options) { [weak self] _, error in
            self?.logger.error("unUserNotificationCenter authorization request error: \(error.debugDescription)")
        }
    }
    
    public func add(for request: UNNotificationRequest) {
        logger.info("Adding following non timed notification: \(request.description)")
        unUserNotificationCenter.add(request)
    }
    
    public func addWithTimer(for request: UNNotificationRequest, and delay: TimeInterval = 5) {
        logger.info("Adding following timed notification: \(request.description), with removal delay: \(delay)")

        unUserNotificationCenter.add(request)
        currentTimers[request.identifier] = .scheduledTimer(withTimeInterval: delay,
                                                            repeats: false) { [weak self] _ in
            guard let self else { return }
            let id = request.identifier
            self.logger.info("Clearing notification with id: \(id)")
            self.unUserNotificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
            self.stopTimer(with: id)
        }
    }
}

// MARK: Utils
private extension NotificationService {
    func stopTimer(with id: String) {
        if let timer = self.currentTimers[id] {
            timer.invalidate()
        }
        currentTimers.removeValue(forKey: id)
    }
}
