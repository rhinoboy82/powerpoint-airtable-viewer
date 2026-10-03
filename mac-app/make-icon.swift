// Draws an installer's monogram as a macOS icon set, then iconutil:
//   swift make-icon.swift <out>.iconset [TEXT TILE INK]
// Defaults to RoomSum's (the site's favicon: "RS" on the sky tile); the Live
// Web Slide Viewer passes "LV" on its add-in's blue, in white.
// The tile sits on Apple's icon grid, 824 of 1024 with the corners rounded.
import AppKit

let args = CommandLine.arguments
let out = args[1]
let label = args.count > 2 ? args[2] : "RS"
func color(_ hex: String) -> NSColor {
  let v = Int(hex, radix: 16) ?? 0
  return NSColor(srgbRed: CGFloat((v >> 16) & 0xff) / 255, green: CGFloat((v >> 8) & 0xff) / 255,
                 blue: CGFloat(v & 0xff) / 255, alpha: 1)
}
try FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
let sizes: [(String, Int)] = [
  ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
  ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
  ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
let sky = color(args.count > 3 ? args[3] : "00BCFF")
let ink = color(args.count > 4 ? args[4] : "0A0A0A")

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
  let text = NSAttributedString(string: label, attributes: [
    .font: font, .foregroundColor: ink, .kern: -tile / 64,
  ])
  let width = text.size().width
  let baseline = origin + tile * (1 - 45.0 / 64.0)
  text.draw(at: NSPoint(x: origin + (tile - width) / 2, y: baseline + font.descender))
  NSGraphicsContext.restoreGraphicsState()
  try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name).png"))
}
