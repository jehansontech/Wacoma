//
//  Task+Extensions.swift
//  Wacoma
//
//  Created by Jim Hanson on 6/12/23.
//

import Foundation

extension Task where Success == Never, Failure == Never {

    public static func uncheckedSleep(seconds: TimeInterval) async {
        do {
            try await Task.sleep(nanoseconds: UInt64(1000000000 * seconds))
        }
        catch {
            // NOP
        }
    }
}
