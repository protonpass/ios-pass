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

import Combine
import Foundation
import UserNotifications

public protocol LocalNotificationServicing {
    func requestNotificationPermission(with options: UNAuthorizationOptions)
    
    func add(for request: UNNotificationRequest)
    func addWithTimer(for request: UNNotificationRequest, and delay: TimeInterval)
}

public extension LocalNotificationServicing {
    func requestNotificationPermission(with options: UNAuthorizationOptions = [.alert]) {
        requestNotificationPermission(with: options)
    }
}

public final class NotificationService: LocalNotificationServicing {
    private let unUserNotificationCenter: UNUserNotificationCenter
    private var currentTimers: [String: Timer] = [:]
    
    public init(unUserNotificationCenter: UNUserNotificationCenter = UNUserNotificationCenter.current()) {
        self.unUserNotificationCenter = unUserNotificationCenter
    }
    
    public  func requestNotificationPermission(with options: UNAuthorizationOptions = []) {
        unUserNotificationCenter.requestAuthorization(options: options) { _, _ in }
    }
    
    public func add(for request: UNNotificationRequest) {
        unUserNotificationCenter.add(request)
    }
    
    public func addWithTimer(for request: UNNotificationRequest, and delay: TimeInterval = 5) {
        unUserNotificationCenter.add(request)
        currentTimers[request.identifier] = .scheduledTimer(withTimeInterval: delay,
                                                            repeats: false) { [weak self] _ in
            guard let self else { return }
            self.unUserNotificationCenter.removeDeliveredNotifications(withIdentifiers: [request.identifier])
            self.stopTimer(with: request.identifier)
        }
    }
    
    private func stopTimer(with id: String) {
        if let timer = self.currentTimers[id] {
            timer.invalidate()
        }
        currentTimers.removeValue(forKey: id)
    }
}
