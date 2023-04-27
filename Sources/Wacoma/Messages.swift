//
//  Messages.swift
//  Wacoma
//
//  Created by Jim Hanson on 10/20/22.
//

import Foundation

extension Thread {

    public var nameForDebugging: String {
        if self.isMainThread {
            return "main"
        }
        else if let name = self.name, !name.isEmpty {
            return name
        }
        else if let seqNum = self.value(forKeyPath: "private.seqNum"),
                let number = Int("\(seqNum)") {
            return String(format: "%04d", number)
        }
        else {
            return "    ?"
        }
    }
}

extension Notification.Name {
    public static var userMessage: Notification.Name { return .init("userMessage") }
}

public struct UserMessage: Codable, Sendable {

    public let messageNumber: Int

    public let priority: Priority

    public let text: String

    public enum Priority: Int, Comparable, Codable, Sendable {

        case low = 0
        case normal = 1
        case high = 2
        case crash = 3

        public static func < (lhs: UserMessage.Priority, rhs: UserMessage.Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

actor MessagePublisher {

    private var messageCounter: Int = 0

    func publishMessage(_ text: String, _ priority: UserMessage.Priority = .normal) async -> Int {
        let messageNumber = nextMessageNumber()
        let message = UserMessage(messageNumber: messageNumber, priority: priority, text: text)
        await MainActor.run {
            NotificationCenter.default.post(name: .userMessage, object: message)
        }
        return messageNumber
    }

    private func nextMessageNumber() -> Int {
        messageCounter += 1
        return messageCounter
    }
}

public struct Messages {

    public static let startTime = Date()

    public static var displayTimeForDebugging: String {
        return makeDisplayTime(Int(1000 * Date().timeIntervalSince(startTime)))
    }

    public static var showThreadName: Bool = true

    public static var showDebugToUser: Bool = false

    private static var publisher = MessagePublisher()

    public static func asyncUser(_ text: String, _ priority: UserMessage.Priority = .normal) async -> Int {
        return await publisher.publishMessage(text, priority)
    }

    public static func user(_ text: String, _ priority: UserMessage.Priority = .normal) {
        Task {
            await asyncUser(text, priority)
        }
    }

    public static func debug(_ displayTime: String, _ context: String, _ text: String) {

        let ctx = context.isEmpty ? " " : " \(context): "
        let msg = showThreadName
        ? String(format: "[%@][%@]%@%@", displayTime, Thread.current.nameForDebugging, ctx, text)
        : String(format: "[%@]%@%@", displayTime, context, text)

        if showDebugToUser {
            user(msg, .low)
        }
        print(msg)
    }

    public static func debug(_ context: String, _ text: String) {
        debug(displayTimeForDebugging, context, text)
    }

    public static func debug(_ text: String) {
        debug(displayTimeForDebugging, "", text)
    }

    private static func makeDisplayTime(_ totalMillis: Int) -> String {
        var millis = totalMillis
        var seconds = millis / 1000
        millis -= 1000 * seconds
        if seconds < 60 {
            return String(format: "00:%02d.%03d", seconds, millis)
        }

        var minutes = seconds / 60
        seconds -= 60 * minutes
        if minutes < 60 {
            return String(format: "%02d:%02d.%03d", minutes, seconds, millis)
        }

        var hours = minutes / 60
        minutes -= 60 * hours
        if hours < 24 {
            return String(format: "%d:%02d:%02d.%03d", hours, minutes, seconds, millis)
        }

        let days = hours / 24
        hours -= 24 * days
        return (days == 1)
        ? String(format: "%d day %d:%02d:%02d.%03d", days, hours, minutes, seconds, millis)
        : String(format: "%d days %d:%02d:%02d.%03d", days, hours, minutes, seconds, millis)
    }
}
