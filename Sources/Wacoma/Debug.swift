//
//  Debug.swift
//
//  Created by Jim Hanson on 5/6/21.
//

import Foundation

fileprivate var debugEnabled: Bool = false

public func setDebug(enabled: Bool) {
    debugEnabled = enabled
}

public func debug(_ message: String) {
    if debugEnabled {
        print("[\(Thread.current.isMainThread ? "main" : "background")] \(message)")
    }
}

public func debug(_ context: String, _ message: String) {
    if debugEnabled {
        print("[\(Thread.current.isMainThread ? "main" : "background"), \(context)] \(message)")
    }
}
