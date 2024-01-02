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

@preconcurrency import UserNotifications

public protocol LocalNotificationServiceProtocol: Sendable {
    func requestNotificationPermission(with options: UNAuthorizationOptions)

    func add(for request: UNNotificationRequest)
    func addWithTimer(for request: UNNotificationRequest, and delay: TimeInterval)
}

public extension LocalNotificationServiceProtocol {
    func requestNotificationPermission(with options: UNAuthorizationOptions = [.alert]) {
        requestNotificationPermission(with: options)
    }
}

public final class NotificationService: LocalNotificationServiceProtocol, Sendable {
    private let unUserNotificationCenter: UNUserNotificationCenter
    private var currentTimers: [String: Timer] = [:]
    private let logger: Logger

    public init(logManager: any LogManagerProtocol,
                unUserNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.unUserNotificationCenter = unUserNotificationCenter
        logger = .init(manager: logManager)
    }

    public func requestNotificationPermission(with options: UNAuthorizationOptions = []) {
        unUserNotificationCenter.requestAuthorization(options: options) { [weak self] _, error in
            guard let self else { return }
            logger.error("unUserNotificationCenter authorization request error: \(error.debugDescription)")
        }
    }

    public func add(for request: UNNotificationRequest) {
        logger.info("Adding following non timed notification: \(request.description)")
        unUserNotificationCenter.add(request)
    }

    public func addWithTimer(for request: UNNotificationRequest, and delay: TimeInterval = 5) {
        logger.info("Adding following timed notification: \(request.description), with removal delay: \(delay)")

        unUserNotificationCenter.add(request)
        let id = request.identifier
        currentTimers[request.identifier] = .scheduledTimer(withTimeInterval: delay,
                                                            repeats: false) { [weak self] _ in
            guard let self else { return }
            logger.info("Clearing notification with id: \(id)")
            unUserNotificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
            stopTimer(with: id)
        }
    }
}

// MARK: Utils

private extension NotificationService {
    func stopTimer(with id: String) {
        if let timer = currentTimers[id] {
            timer.invalidate()
        }
        currentTimers.removeValue(forKey: id)
    }
}
