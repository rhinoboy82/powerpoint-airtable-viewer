// Draws an installer's icon as a macOS icon set, then iconutil:
//   swift make-icon.swift <out>.iconset [TEXT TILE INK] [band=RRGGBB] [cue=none]
// Defaults to RoomSum's: the site's favicon, "RS" in near-black Arial Bold on the sky tile. The Live
// Web Slide Viewer passes "LV" on its add-in's blue, in white:  LV 2D7FF9 FFFFFF
//
// Replaces PowerPoint Viewer/mac-app/make-icon.swift (2026-10-06). Same command line; the extras are
// optional and named. It is drawn in CoreGraphics from nothing (no image assets), so the same text and
// colours always give the same pixels.
//
// What it draws, in the add-in icons' 64-unit grid (RS cap 6..34, band 40..64), on Apple's icon grid:
//   - the tile is 824 of 1024, centred, on a TRANSPARENT canvas, in a continuous-corner rounded square
//     (corner radius 22.5 percent, Figma-style smoothing 0.6, the family Apple's icon shape belongs to);
//   - under it a wide soft shadow and a tight contact shadow, both alpha only, both inside the canvas;
//   - the body: a luminous vertical gradient of TILE (lighter at the top, a touch deeper at the foot);
//   - a soft glass highlight across the top that sags in the middle (the add-in icons' highlight);
//   - TEXT as the favicon sets it (Arial Bold 39.1 of 64, tracking -1/40 em), flat, TEXT's ink colour,
//     with a faint lip of light beneath it so it sits on the glass;
//   - the installer cue: a cobalt glass band across the foot holding a white down-arrow, the add-in
//     icons' "coloured band with a mark" with an arrow in place of a letter. The band colour is TILE
//     turned toward blue and darkened (sky gives the Start add-in's cobalt), or band=RRGGBB;
//   - a thin directional rim of light (brightest top left) and a faint dark edge, for light desktops.
// Small sizes are drawn natively, not shrunk: horizontal edges and the arrow's width snap to whole
// pixels up to 128, and the 16 px file uses a 14 px tile (a 12.9 px one would have soft edges).
//
// Nothing in the tile is transparent, so on a desktop the only see-through parts are the margin and the
// shadow. NOT drawn: Apple's layered Icon Composer (.icon) format, so macOS's own dark, clear and
// tinted treatments are not applied to this icon.
import CoreGraphics
import CoreText
import Foundation
import ImageIO

// MARK: - Parameters (design units are the 64 x 64 grid of the add-in icons unless a name says px)

let canvasGrid = 1024.0           // the master canvas
let tileOnGrid = 824.0            // Apple's grid: the tile on the 1024 canvas
let cornerRadius = 14.4           // 22.5 percent of 64
let cornerSmoothing = 0.6         // continuous corners
let fontSize = 39.1               // favicon 40, as in the add-in icons
let baselineY = 34.0              // RS cap spans 6..34
let trackingEm = -1.0 / 40.0      // letter-spacing -1 at font-size 40
let maxTextWidth = 54.0           // longer text is scaled down to fit
let bandTopY = 40.0
let bandHueShift = 11.0           // degrees toward blue, so sky 195 gives the cobalt at 206
let bandSatTop = 0.93, bandBrightTop = 0.62       // sky -> #0b5d9e (the Start add-in's band)
let bandSatFoot = 0.95, bandBrightFoot = 0.50     // sky -> about #08497f
let arrowTop = 44.2, arrowShoulder = 51.6, arrowTip = 59.6
let arrowHeadWidth = 14.5, arrowStemWidth = 5.4
let shadowWide = (dy: 14.0, blur: 34.0, alpha: 0.34)   // at 1024, scaled with the size
let shadowContact = (dy: 3.0, blur: 7.0, alpha: 0.30)

// MARK: - Colour

struct RGB { var r: Double, g: Double, b: Double }
func parseHex(_ s: String) -> RGB {
  var h = s; if h.hasPrefix("#") { h.removeFirst() }
  let v = Int(h, radix: 16) ?? 0
  return RGB(r: Double((v >> 16) & 255) / 255, g: Double((v >> 8) & 255) / 255, b: Double(v & 255) / 255)
}
func mix(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
  RGB(r: a.r + (b.r - a.r) * t, g: a.g + (b.g - a.g) * t, b: a.b + (b.b - a.b) * t)
}
let white = RGB(r: 1, g: 1, b: 1), black = RGB(r: 0, g: 0, b: 0)
func toHSB(_ c: RGB) -> (h: Double, s: Double, v: Double) {
  let mx = max(c.r, c.g, c.b), mn = min(c.r, c.g, c.b), d = mx - mn
  var h = 0.0
  if d > 0 {
    if mx == c.r { h = ((c.g - c.b) / d).truncatingRemainder(dividingBy: 6) }
    else if mx == c.g { h = (c.b - c.r) / d + 2 } else { h = (c.r - c.g) / d + 4 }
    h *= 60; if h < 0 { h += 360 }
  }
  return (h, mx == 0 ? 0 : d / mx, mx)
}
func fromHSB(_ hue: Double, _ s: Double, _ v: Double) -> RGB {
  let h = hue.truncatingRemainder(dividingBy: 360)
  let c = v * s, x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1)), m = v - c
  let (r, g, b): (Double, Double, Double)
  switch Int(h / 60) % 6 {
  case 0: (r, g, b) = (c, x, 0); case 1: (r, g, b) = (x, c, 0); case 2: (r, g, b) = (0, c, x)
  case 3: (r, g, b) = (0, x, c); case 4: (r, g, b) = (x, 0, c); default: (r, g, b) = (c, 0, x)
  }
  return RGB(r: r + m, g: g + m, b: b + m)
}
func luminance(_ c: RGB) -> Double {
  func f(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b)
}
func cg(_ c: RGB, _ a: Double = 1) -> CGColor { CGColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: a) }
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
func gradient(_ stops: [(Double, CGColor)]) -> CGGradient {
  CGGradient(colorsSpace: srgb, colors: stops.map { $0.1 } as CFArray, locations: stops.map { CGFloat($0.0) })!
}

// MARK: - Shapes

func rad(_ d: Double) -> Double { d * .pi / 180 }

/// A rounded square with continuous (smoothed) corners, y down. The corner is the top-right one
/// worked out once, relative to its start point, then turned a quarter at a time.
func squircle(_ r: CGRect, radius R0: Double, smoothing s: Double = cornerSmoothing) -> CGPath {
  let W = Double(r.width), H = Double(r.height)
  var R = R0
  if (1 + s) * R > min(W, H) / 2 { R = min(W, H) / 2 / (1 + s) }
  let p = (1 + s) * R                                   // how far along each edge the curve reaches
  let arcMeasure = 90 * (1 - s)                         // the circular part, degrees
  let arcLength = sin(rad(arcMeasure / 2)) * R * 2.0.squareRoot()
  let p3p4 = R * tan(rad((90 - arcMeasure) / 2 / 2))
  let beta = 45 * s
  let c = p3p4 * cos(rad(beta)), d = c * tan(rad(beta))
  let b = (p - arcLength - c - d) / 3, a = 2 * b
  let e1 = CGPoint(x: a + b + c, y: d)
  let e2 = CGPoint(x: e1.x + arcLength, y: e1.y + arcLength)
  let th = rad(arcMeasure), k = 4.0 / 3.0 * tan(th / 4) * R
  let t1 = CGPoint(x: cos(rad(beta)), y: sin(rad(beta)))
  let t2 = CGPoint(x: cos(rad(beta) + th), y: sin(rad(beta) + th))
  let segments: [(CGPoint, CGPoint, CGPoint)] = [
    (CGPoint(x: a, y: 0), CGPoint(x: a + b, y: 0), e1),
    (CGPoint(x: e1.x + k * t1.x, y: e1.y + k * t1.y), CGPoint(x: e2.x - k * t2.x, y: e2.y - k * t2.y), e2),
    (CGPoint(x: e2.x + d, y: e2.y + c), CGPoint(x: e2.x + d, y: e2.y + b + c), CGPoint(x: e2.x + d, y: e2.y + a + b + c)),
  ]
  let x0 = Double(r.minX), y0 = Double(r.minY)
  let starts = [CGPoint(x: x0 + W - p, y: y0), CGPoint(x: x0 + W, y: y0 + H - p),
                CGPoint(x: x0 + p, y: y0 + H), CGPoint(x: x0, y: y0 + p)]
  func turn(_ q: CGPoint, _ quarter: Int) -> CGPoint {
    switch quarter {
    case 0: return q
    case 1: return CGPoint(x: -q.y, y: q.x)
    case 2: return CGPoint(x: -q.x, y: -q.y)
    default: return CGPoint(x: q.y, y: -q.x)
    }
  }
  let path = CGMutablePath()
  path.move(to: starts[0])
  for quarter in 0..<4 {
    let s0 = starts[quarter]
    if quarter > 0 { path.addLine(to: s0) }
    for seg in segments {
      let c1 = turn(seg.0, quarter), c2 = turn(seg.1, quarter), e = turn(seg.2, quarter)
      path.addCurve(to: CGPoint(x: s0.x + e.x, y: s0.y + e.y),
                    control1: CGPoint(x: s0.x + c1.x, y: s0.y + c1.y),
                    control2: CGPoint(x: s0.x + c2.x, y: s0.y + c2.y))
    }
  }
  path.closeSubpath()
  return path
}

/// The text as outlines, so it can be filled, shadowed and clipped like any other shape. Arial Bold, as
/// the favicon; centred on the advance width the way SVG's text-anchor "middle" does.
func textOutline(_ text: String, size F: Double, tracking: Double, centerX: Double, baseline: Double) -> CGPath {
  var font = CTFontCreateWithName("Arial-BoldMT" as CFString, CGFloat(F), nil)
  if (CTFontCopyPostScriptName(font) as String) != "Arial-BoldMT" {
    FileHandle.standardError.write("warning: Arial Bold not found, drawing the monogram in Helvetica Bold\n".data(using: .utf8)!)
    font = CTFontCreateWithName("Helvetica-Bold" as CFString, CGFloat(F), nil)
  }
  let chars = Array(text.utf16)
  var glyphs = [CGGlyph](repeating: 0, count: chars.count)
  CTFontGetGlyphsForCharacters(font, chars, &glyphs, chars.count)
  var advances = [CGSize](repeating: .zero, count: chars.count)
  CTFontGetAdvancesForGlyphs(font, .horizontal, glyphs, &advances, chars.count)
  var x = centerX - advances.reduce(0.0) { $0 + Double($1.width) + tracking } / 2
  let out = CGMutablePath()
  for (i, g) in glyphs.enumerated() {
    if let outline = CTFontCreatePathForGlyph(font, g, nil) {
      out.addPath(outline, transform: CGAffineTransform(translationX: CGFloat(x), y: CGFloat(baseline)).scaledBy(x: 1, y: -1))
    }
    x += Double(advances[i].width) + tracking
  }
  return out
}

// MARK: - The icon

struct Spec {
  var label = "RS"
  var tile = parseHex("00BCFF")
  var ink = parseHex("0A0A0A")
  var band: RGB? = nil        // nil: derived from the tile colour
  var cue = true              // the arrow band; false draws the plain glass tile
}

/// The side of the tile in pixels for a canvas of `px`: Apple's 824 of 1024, kept to an even pixel count
/// below 512 so edges stay crisp; 16 px uses 14, since the grid's 12.9 px would be all soft edge.
func tileSide(_ px: Int) -> Double {
  if px >= 512 { return Double(px) * tileOnGrid / canvasGrid }
  if px == 16 { return 14 }
  return (Double(px) * tileOnGrid / canvasGrid / 2).rounded() * 2
}

func renderIcon(px: Int, spec: Spec) -> CGImage {
  let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0, space: srgb,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  ctx.setAllowsAntialiasing(true); ctx.setShouldAntialias(true); ctx.interpolationQuality = .high
  let P = Double(px)
  let tile = tileSide(px)
  let origin = (P - tile) / 2
  let U = tile / 64                        // device pixels per design unit
  let sh = P / canvasGrid                  // shadows are specified at 1024 and scale with the canvas
  // y down, design units, origin at the tile's top left
  ctx.translateBy(x: 0, y: CGFloat(P)); ctx.scaleBy(x: 1, y: -1)
  ctx.translateBy(x: CGFloat(origin), y: CGFloat(origin)); ctx.scaleBy(x: CGFloat(U), y: CGFloat(U))
  /// Up to 128 px, horizontal edges land on whole device pixels.
  func snap(_ u: Double) -> Double { px > 128 ? u : ((origin + u * U).rounded() - origin) / U }
  /// Up to 128 px, a symmetric width is a whole, even number of pixels, so both edges are crisp.
  func snapWidth(_ u: Double) -> Double { px > 128 ? u : max(2, 2 * (u * U / 2).rounded()) / U }

  let lightInk = luminance(spec.ink) > 0.5          // white print: keep the field from going pale, or its contrast drops below today's
  let sky = spec.tile
  let hsb = toHSB(sky)
  let top = lightInk ? sky : mix(sky, white, 0.35)
  let foot = fromHSB(hsb.h, hsb.s, hsb.v * (lightInk ? 0.80 : 0.90))
  let bandTop = spec.band ?? fromHSB(hsb.h + bandHueShift, hsb.s * bandSatTop, hsb.v * bandBrightTop)
  let bandFoot = spec.band.map { mix($0, black, 0.20) } ?? fromHSB(hsb.h + bandHueShift, hsb.s * bandSatFoot, hsb.v * bandBrightFoot)
  let shape = squircle(CGRect(x: 0, y: 0, width: 64, height: 64), radius: cornerRadius)

  // 1. Shadows, cast by an underlay of the tile's own shape (the body covers it).
  func castShadow(_ s: (dy: Double, blur: Double, alpha: Double)) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s.dy * sh), blur: CGFloat(s.blur * sh), color: cg(black, s.alpha))
    ctx.addPath(shape); ctx.setFillColor(cg(mix(foot, black, 0.4))); ctx.fillPath()
    ctx.restoreGState()
  }
  castShadow(shadowWide); castShadow(shadowContact)

  // 2. The body.
  ctx.saveGState()
  ctx.addPath(shape); ctx.clip()
  ctx.drawLinearGradient(gradient([(0, cg(top)), (0.5, cg(sky)), (1, cg(foot))]),
                         start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 64), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

  // 3. The band, under the monogram's glow and the arrow.
  if spec.cue {
    let y0 = snap(bandTopY)
    ctx.saveGState()
    ctx.clip(to: CGRect(x: -1, y: y0, width: 66, height: 30))
    ctx.drawLinearGradient(gradient([(0, cg(bandTop)), (1, cg(bandFoot))]), start: CGPoint(x: 0, y: y0), end: CGPoint(x: 0, y: 64), options: [])
    ctx.drawLinearGradient(gradient([(0, cg(white, 0.20)), (0.08, cg(white, 0.07)), (0.45, cg(white, 0)), (1, cg(black, 0.10))]),
                           start: CGPoint(x: 0, y: y0), end: CGPoint(x: 0, y: 64), options: [])
    ctx.setFillColor(cg(white, 0.32)); ctx.fill(CGRect(x: -1, y: y0, width: 66, height: 0.5))
    ctx.restoreGState()
    // a hair of shade just above the band, so it reads as a step
    ctx.drawLinearGradient(gradient([(0, cg(black, 0)), (1, cg(black, 0.10))]),
                           start: CGPoint(x: 0, y: y0 - 2.5), end: CGPoint(x: 0, y: y0), options: [])
  }

  // 4. Glass highlight across the top, sagging in the middle (the add-in icons' highlight, softened).
  let sheen = CGMutablePath()
  sheen.move(to: CGPoint(x: -1, y: -1)); sheen.addLine(to: CGPoint(x: 65, y: -1)); sheen.addLine(to: CGPoint(x: 65, y: 18.75))
  sheen.addCurve(to: CGPoint(x: -1, y: 18.75), control1: CGPoint(x: 48, y: 23.125), control2: CGPoint(x: 16, y: 23.125))
  sheen.closeSubpath()
  ctx.saveGState()
  ctx.addPath(sheen); ctx.clip()
  let sheenScale = lightInk ? 0.25 : 1.0
  ctx.drawLinearGradient(gradient([(0, cg(white, 0.30 * sheenScale)), (0.6, cg(white, 0.14 * sheenScale)), (1, cg(white, 0.04 * sheenScale))]),
                         start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 23), options: [.drawsBeforeStartLocation])
  ctx.restoreGState()

  // 5. The monogram, flat, as the favicon draws it.
  var size = fontSize
  let measure = textOutline(spec.label, size: size, tracking: size * trackingEm, centerX: 0, baseline: 0).boundingBoxOfPath
  if Double(measure.width) > maxTextWidth { size *= maxTextWidth / Double(measure.width) }
  let monogram = textOutline(spec.label, size: size, tracking: size * trackingEm, centerX: 32, baseline: snap(baselineY))
  if U > 3 {   // a faint lip of light (or shade, under white print) beneath the letters
    ctx.saveGState(); ctx.translateBy(x: 0, y: 0.55)
    ctx.addPath(monogram); ctx.setFillColor(cg(lightInk ? black : white, lightInk ? 0.18 : 0.16)); ctx.fillPath()
    ctx.restoreGState()
  }
  ctx.addPath(monogram); ctx.setFillColor(cg(spec.ink)); ctx.fillPath()

  // 6. The arrow, one object so its soft shadow is cast once.
  if spec.cue {
    let topY = snap(arrowTop), shoulderY = snap(arrowShoulder), tipY = snap(arrowTip)
    let stem = snapWidth(arrowStemWidth), head = snapWidth(arrowHeadWidth)
    let a = CGMutablePath()
    a.move(to: CGPoint(x: 32 - stem / 2, y: topY)); a.addLine(to: CGPoint(x: 32 + stem / 2, y: topY))
    a.addLine(to: CGPoint(x: 32 + stem / 2, y: shoulderY)); a.addLine(to: CGPoint(x: 32 + head / 2, y: shoulderY))
    a.addLine(to: CGPoint(x: 32, y: tipY)); a.addLine(to: CGPoint(x: 32 - head / 2, y: shoulderY))
    a.addLine(to: CGPoint(x: 32 - stem / 2, y: shoulderY)); a.closeSubpath()
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -1.1 * U), blur: CGFloat(1.6 * U), color: cg(black, 0.38))
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    ctx.addPath(a); ctx.setFillColor(cg(white)); ctx.setStrokeColor(cg(white)); ctx.setLineWidth(px > 128 ? 1.3 : 0.6); ctx.setLineJoin(.round)
    ctx.drawPath(using: .fillStroke)
    ctx.endTransparencyLayer()
    ctx.restoreGState()
  }
  ctx.restoreGState()   // the body's clip

  // 7. A thin rim of light, brightest at the top left, and a faint dark edge outside it.
  let rimWidth = max(0.55, 1.0 / U)
  ctx.saveGState()
  ctx.addPath(squircle(CGRect(x: rimWidth / 2, y: rimWidth / 2, width: 64 - rimWidth, height: 64 - rimWidth), radius: cornerRadius - rimWidth / 2))
  ctx.setLineWidth(CGFloat(rimWidth)); ctx.replacePathWithStrokedPath(); ctx.clip()
  ctx.drawLinearGradient(gradient([(0, cg(white, 0.90)), (0.28, cg(white, 0.30)), (0.62, cg(white, 0.04)), (1, cg(white, 0.26))]),
                         start: CGPoint(x: 8, y: 0), end: CGPoint(x: 56, y: 64), options: [])
  ctx.restoreGState()
  let edge = max(0.4, 0.7 / U)
  ctx.saveGState()
  ctx.addPath(squircle(CGRect(x: -edge / 2, y: -edge / 2, width: 64 + edge, height: 64 + edge), radius: cornerRadius + edge / 2))
  ctx.setLineWidth(CGFloat(edge)); ctx.replacePathWithStrokedPath(); ctx.clip()
  ctx.drawLinearGradient(gradient([(0, cg(black, 0.03)), (1, cg(black, 0.16))]),
                         start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 64), options: [])
  ctx.restoreGState()
  return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to path: String) {
  let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, "public.png" as CFString, 1, nil)!
  CGImageDestinationAddImage(dest, image, nil)
  if !CGImageDestinationFinalize(dest) { FileHandle.standardError.write("could not write \(path)\n".data(using: .utf8)!); exit(1) }
}

// MARK: - Command line

let arguments = Array(CommandLine.arguments.dropFirst())
let named = arguments.filter { $0.contains("=") }
let positional = arguments.filter { !$0.contains("=") }
guard let outPath = positional.first else {
  FileHandle.standardError.write("usage: swift make-icon.swift <out>.iconset [TEXT TILE INK] [band=RRGGBB] [cue=none]\n".data(using: .utf8)!)
  exit(2)
}
var spec = Spec()
if positional.count > 1 { spec.label = positional[1] }
if positional.count > 2 { spec.tile = parseHex(positional[2]) }
if positional.count > 3 { spec.ink = parseHex(positional[3]) }
for option in named {
  let parts = option.split(separator: "=", maxSplits: 1).map(String.init)
  switch parts[0] {
  case "band": spec.band = parseHex(parts[1])
  case "cue": spec.cue = parts[1] != "none"
  default: FileHandle.standardError.write("unknown option \(parts[0])\n".data(using: .utf8)!); exit(2)
  }
}
try FileManager.default.createDirectory(atPath: outPath, withIntermediateDirectories: true)
let files: [(String, Int)] = [
  ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
  ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
  ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
var rendered: [Int: CGImage] = [:]
for (name, px) in files {
  if rendered[px] == nil { rendered[px] = renderIcon(px: px, spec: spec) }
  writePNG(rendered[px]!, to: "\(outPath)/\(name).png")
}
