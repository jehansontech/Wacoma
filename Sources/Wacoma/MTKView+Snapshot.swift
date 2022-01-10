//
//  MTKView+Snapshot.swift
//  
//
//  Created by Jim Hanson on 1/8/22.

import MetalKit

extension MTKView {

    public func takeSnapshot() -> CGImage? {
        guard
            let texture = self.currentDrawable?.texture
        else {
            return nil
        }

        let width = texture.width
        let height   = texture.height
        let rowBytes = texture.width * 4
        let p = malloc(width * height * 4)
        texture.getBytes(p!, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)

        let pColorSpace = CGColorSpaceCreateDeviceRGB()

        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)

        let selftureSize = texture.width * texture.height * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            return
        }
        let provider = CGDataProvider(dataInfo: nil, data: p!, size: selftureSize, releaseData: releaseMaskImagePixelData)
        return CGImage(width: texture.width,
                       height: texture.height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 32,
                       bytesPerRow: rowBytes,
                       space: pColorSpace,
                       bitmapInfo: bitmapInfo,
                       provider: provider!,
                       decode: nil,
                       shouldInterpolate: true,
                       intent: CGColorRenderingIntent.defaultIntent)
    }
}

//
//  Image+Extensions.swift
//
//
//  Created by Jim Hanson on 1/5/22.
//

import SwiftUI

#if os(iOS) // =========================================================================

extension CGImage {

    public func save() {
        let uiImage = UIImage(cgImage: self)
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
    }
}

#elseif os(macOS) // =========================================================================

extension CGImage {

    public func save() {
        let timestamp: String = makeTimestamp()
        let nsImage = NSImage(cgImage: self, size: NSSize(width: self.width, height: self.height))
        let desktopURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first!
        let destinationURL = desktopURL.appendingPathComponent("snapshot.\(timestamp).png")
        if nsImage.pngWrite(to: destinationURL, options: .withoutOverwriting) {
            print("Image saved to \(destinationURL)")
        }
    }

    public func makeTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}

extension NSImage {

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
}

#endif // =========================================================================


