// Draws the RoomSum monogram (the site's favicon: "RS" on the sky tile) as a
// macOS icon set: usage `swift make-icon.swift <out>.iconset`, then iconutil.
// The tile sits on Apple's icon grid, 824 of 1024 with the corners rounded.
import AppKit

let out = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
let sizes: [(String, Int)] = [
  ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
  ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
  ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
let sky = NSColor(srgbRed: 0, green: 0xbc / 255.0, blue: 1, alpha: 1)
let ink = NSColor(srgbRed: 0x0a / 255.0, green: 0x0a / 255.0, blue: 0x0a / 255.0, alpha: 1)

for (name, px) in sizes {
  let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  let canvas = CGFloat(px)
  let tile = canvas * 824 / 1024
  let origin = (canvas - tile) / 2
  let rect = NSRect(x: origin, y: origin, width: tile, height: tile)
  sky.setFill()
  NSBezierPath(roundedRect: rect, xRadius: tile * 0.225, yRadius: tile * 0.225).fill()
  // The favicon's proportions: 40 of 64 type, baseline 45 of 64 down.
  let font = NSFont(name: "Arial-BoldMT", size: tile * 40 / 64) ?? NSFont.boldSystemFont(ofSize: tile * 40 / 64)
  let text = NSAttributedString(string: "RS", attributes: [
    .font: font, .foregroundColor: ink, .kern: -tile / 64,
  ])
  let width = text.size().width
  let baseline = origin + tile * (1 - 45.0 / 64.0)
  text.draw(at: NSPoint(x: origin + (tile - width) / 2, y: baseline + font.descender))
  NSGraphicsContext.restoreGraphicsState()
  try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
}
