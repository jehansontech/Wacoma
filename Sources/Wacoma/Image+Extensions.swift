//
//  Image+Extensions.swift
//
//
//  Created by Jim Hanson on 1/5/22.
//

import SwiftUI

#if os(iOS) // =========================================================================

extension UIImage {

    public func save() {
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
    }
}

extension CGImage {

    public func save() {
        UIImage(cgImage: self).save()
    }
}

#elseif os(macOS) // =========================================================================

extension NSImage {

    public func save() {
        let timestamp: String = makeTimestamp()
        let desktopURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        let destinationURL = desktopURL.appendingPathComponent("snapshot.\(timestamp).png")
        if pngWrite(to: destinationURL, options: .withoutOverwriting) {
            print("Image saved to \(destinationURL)")
        }
    }

    public var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }

    public func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }

    public func makeTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}

extension CGImage {

    public func save() {
        NSImage(cgImage: self, size: NSSize(width: self.width, height: self.height)).save()
    }
}

#endif // =========================================================================


