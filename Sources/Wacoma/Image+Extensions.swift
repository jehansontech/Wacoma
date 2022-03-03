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
        let timestamp: String = makeTimestamp()
        UIImage(cgImage: self).save()
        print("Image saved to Photos. timestamp: \(timestamp)")
    }
}

#elseif os(macOS) // =========================================================================

extension NSImage {

    public func save() {
        let timestamp: String = makeTimestamp()
        let filename = "snapshot.\(timestamp).png"
        let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        let destinationURL = picturesURL.appendingPathComponent(filename)
        if pngWrite(to: destinationURL, options: .withoutOverwriting) {
            print("Image saved to Pictures/\(destinationURL)")
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


