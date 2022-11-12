//
//  Image+Extensions.swift
//
//
//  Created by Jim Hanson on 1/5/22.
//

import SwiftUI

#if os(iOS) // =========================================================================

extension UIImage {

    public func save() -> String {
        let timestamp: String = makeTimestamp()
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
        return "Image saved to Photos with timestamp \(timestamp)"
    }

    public func makeTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }

}

extension CGImage {

    public func save() -> String {
        return UIImage(cgImage: self).save()
    }
}

#elseif os(macOS) // =========================================================================

extension NSImage {

    public func save() -> String {
        let timestamp: String = makeTimestamp()
        let filename = "snapshot.\(timestamp).png"
        let picturesURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        let destinationURL = picturesURL.appendingPathComponent(filename)

        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation),
              let pngData = bitmapImage.representation(using: .png, properties: [:])
        else {
            return "Image capture failed."
        }

        do {
            try pngData.write(to: destinationURL, options: .atomic)
            return "Image saved to Pictures/\(destinationURL.lastPathComponent)"
        }
        catch {
            return "Image save failed. Error: \(error)"
        }
    }

    public func makeTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}

extension CGImage {

    public func save() -> String {
        return NSImage(cgImage: self, size: NSSize(width: self.width, height: self.height)).save()
    }
}

#endif // =========================================================================


