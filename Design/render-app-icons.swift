import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Renders the Varia Radar app icons at 1024×1024 with plain CoreGraphics shapes
// (no SF Symbols: Apple's license doesn't allow them in app icons).
//
//   swift Design/render-app-icons.swift <folder>           side-by-side concept preview
//   swift Design/render-app-icons.swift <folder> --final   ios/ and watch/ icon files
//
// Copy the --final output into the AppIcon.appiconset folders of both apps.

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: sRGB, components: [CGFloat((hex >> 16) & 0xFF) / 255,
                                           CGFloat((hex >> 8) & 0xFF) / 255,
                                           CGFloat(hex & 0xFF) / 255, alpha])!
}

// The app's own palette.
let red: UInt32 = 0xFF3B30, amber: UInt32 = 0xFF9F0A, green: UInt32 = 0x30D158, blue: UInt32 = 0x5A9BE8

/// A canvas with y growing downward, like a design tool.
func canvas(_ width: Int, _ height: Int, opaque: Bool = true) -> CGContext {
    let alpha = opaque ? CGImageAlphaInfo.noneSkipLast : CGImageAlphaInfo.premultipliedLast
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: sRGB, bitmapInfo: alpha.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1, y: -1)
    return ctx
}

func save(_ image: CGImage, _ name: String) {
    let url = URL(fileURLWithPath: outDir).appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// MARK: Shapes

func background(_ ctx: CGContext) {
    let gradient = CGGradient(colorsSpace: sRGB, colors: [rgb(0x262A31), rgb(0x06070A)] as CFArray, locations: [0, 1])!
    let center = CGPoint(x: 512, y: 390)
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 780,
                           options: [.drawsAfterEndLocation])
}

/// An arc of the radar fan, opening upward from `center` (behind the rider).
func arc(_ ctx: CGContext, center: CGPoint, radius: CGFloat, span: CGFloat, width: CGFloat, color: CGColor) {
    let path = CGMutablePath()
    for step in 0...120 {
        let angle = (-90 - span / 2 + span * CGFloat(step) / 120) * .pi / 180
        let point = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
        step == 0 ? path.move(to: point) : path.addLine(to: point)
    }
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setStrokeColor(color)
    ctx.setLineWidth(width)
    ctx.setLineCap(.round)
    ctx.strokePath()
    ctx.restoreGState()
}

func dot(_ ctx: CGContext, _ center: CGPoint, radius: CGFloat, _ hex: UInt32, glow: CGFloat) {
    ctx.saveGState()
    if glow > 0 { ctx.setShadow(offset: .zero, blur: glow, color: rgb(hex, 0.95)) }
    ctx.setFillColor(rgb(hex))
    ctx.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    ctx.restoreGState()
}

func ring(_ ctx: CGContext, _ center: CGPoint, radius: CGFloat, width: CGFloat, color: CGColor) {
    ctx.saveGState()
    ctx.setStrokeColor(color)
    ctx.setLineWidth(width)
    ctx.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
    ctx.restoreGState()
}

func lane(_ ctx: CGContext, top: CGFloat, bottom: CGFloat, width: CGFloat) {
    let rect = CGRect(x: 512 - width / 2, y: top, width: width, height: bottom - top)
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: width / 2, cornerHeight: width / 2, transform: nil))
    ctx.setFillColor(rgb(0xFFFFFF, 0.07))
    ctx.fillPath()
    ctx.restoreGState()
}

/// The blue "you" marker from the app, with softly rounded corners.
func you(_ ctx: CGContext, _ center: CGPoint, width: CGFloat, height: CGFloat) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y - height / 2))
    path.addLine(to: CGPoint(x: center.x + width / 2, y: center.y + height / 2))
    path.addLine(to: CGPoint(x: center.x - width / 2, y: center.y + height / 2))
    path.closeSubpath()
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 34, color: rgb(blue, 0.55))
    ctx.addPath(path)
    ctx.setLineJoin(.round)
    ctx.setLineWidth(22)
    ctx.setFillColor(rgb(blue))
    ctx.setStrokeColor(rgb(blue))
    ctx.drawPath(using: .fillStroke)
    ctx.restoreGState()
}

// MARK: Concepts

/// A: the app's main screen in miniature: a lane of cars sliding down toward you.
func radarLane(_ ctx: CGContext) {
    background(ctx)
    let rider = CGPoint(x: 512, y: 868)
    for (radius, alpha) in [(300.0, 0.08), (500.0, 0.065), (700.0, 0.05)] as [(CGFloat, CGFloat)] {
        arc(ctx, center: rider, radius: radius, span: 64, width: 10, color: rgb(0xFFFFFF, alpha))
    }
    lane(ctx, top: 176, bottom: 800, width: 46)
    dot(ctx, CGPoint(x: 512, y: 280), radius: 44, green, glow: 36)
    dot(ctx, CGPoint(x: 512, y: 476), radius: 56, amber, glow: 44)
    ring(ctx, CGPoint(x: 512, y: 676), radius: 116, width: 12, color: rgb(red, 0.35))
    dot(ctx, CGPoint(x: 512, y: 676), radius: 74, red, glow: 80)
    you(ctx, rider, width: 136, height: 112)
}

/// The radar's coverage: a slice of circle spreading out behind the rider.
func sector(center: CGPoint, radius: CGFloat, span: CGFloat) -> CGPath {
    let path = CGMutablePath()
    path.move(to: center)
    for step in 0...120 {
        let angle = (-90 - span / 2 + span * CGFloat(step) / 120) * .pi / 180
        path.addLine(to: CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
    }
    path.closeSubpath()
    return path
}

/// D: the radar cone behind you, with range rings and three cars shrinking into the distance.
/// `contentScale` pulls everything but the background inward (the Watch's round mask needs it).
func radarCone(_ ctx: CGContext, contentScale: CGFloat) {
    background(ctx)
    ctx.saveGState()
    ctx.translateBy(x: 512, y: 512)
    ctx.scaleBy(x: contentScale, y: contentScale)
    ctx.translateBy(x: -512, y: -512)
    defer { ctx.restoreGState() }

    let rider = CGPoint(x: 512, y: 866)
    let reach: CGFloat = 750, span: CGFloat = 50
    let cone = sector(center: rider, radius: reach, span: span)

    // Coverage: bright near you, fading with distance.
    ctx.saveGState()
    ctx.addPath(cone)
    ctx.clip()
    let fade = CGGradient(colorsSpace: sRGB, colors: [rgb(0xFFFFFF, 0.21), rgb(0xFFFFFF, 0.025)] as CFArray,
                          locations: [0, 1])!
    ctx.drawRadialGradient(fade, startCenter: rider, startRadius: 0, endCenter: rider, endRadius: reach, options: [])
    ctx.restoreGState()

    // Range rings inside the cone, and its outline.
    for radius in [260.0, 460.0, 660.0] as [CGFloat] {
        arc(ctx, center: rider, radius: radius, span: span, width: 7, color: rgb(0xFFFFFF, 0.13))
    }
    ctx.saveGState()
    ctx.addPath(cone)
    ctx.setStrokeColor(rgb(0xFFFFFF, 0.10))
    ctx.setLineWidth(6)
    ctx.setLineJoin(.round)
    ctx.strokePath()
    ctx.restoreGState()

    // Cars: far and small at the top, the close fast one big and glowing.
    dot(ctx, CGPoint(x: 534, y: 262), radius: 30, green, glow: 30)
    dot(ctx, CGPoint(x: 494, y: 460), radius: 44, amber, glow: 40)
    ring(ctx, CGPoint(x: 512, y: 648), radius: 100, width: 11, color: rgb(red, 0.35))
    dot(ctx, CGPoint(x: 512, y: 648), radius: 68, red, glow: 80)
    you(ctx, rider, width: 136, height: 112)
}

// MARK: Final app icons

if CommandLine.arguments.contains("--final") {
    for folder in ["ios", "watch"] {
        try? FileManager.default.createDirectory(atPath: "\(outDir)/\(folder)", withIntermediateDirectories: true)
    }
    let phone = canvas(1024, 1024)
    radarCone(phone, contentScale: 1)
    let phoneIcon = phone.makeImage()!
    save(phoneIcon, "ios/AppIcon.png")
    save(phoneIcon, "ios/AppIcon-Dark.png")   // already a dark design; stops iOS dimming it

    // Tinted home screens use a grayscale version that iOS colours in.
    let gray = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                         space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)!
    gray.draw(phoneIcon, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    save(gray.makeImage()!, "ios/AppIcon-Tinted.png")

    let watch = canvas(1024, 1024)
    radarCone(watch, contentScale: 0.9)
    save(watch.makeImage()!, "watch/AppIcon.png")
    print("Rendered final icons to \(outDir)")
    exit(0)
}

// MARK: Concept preview

let concepts: [(String, (CGContext) -> Void)] = [
    ("concept-a-lane.png", radarLane),
    ("concept-d-cone.png", { radarCone($0, contentScale: 1) }),
]

var images: [CGImage] = []
for (name, draw) in concepts {
    let ctx = canvas(1024, 1024)
    draw(ctx)
    let image = ctx.makeImage()!
    save(image, name)
    images.append(image)
}

// Side-by-side preview, each masked to the iPhone's rounded icon shape.
let tile: CGFloat = 600, gap: CGFloat = 80
let count = CGFloat(images.count)
let sheet = canvas(Int(tile * count + gap * (count + 1)), Int(tile + gap * 2))
sheet.setFillColor(rgb(0xE9E9EE))
sheet.fill(CGRect(x: 0, y: 0, width: tile * count + gap * (count + 1), height: tile + gap * 2))
for (index, image) in images.enumerated() {
    let rect = CGRect(x: gap + CGFloat(index) * (tile + gap), y: gap, width: tile, height: tile)
    sheet.saveGState()
    sheet.addPath(CGPath(roundedRect: rect, cornerWidth: tile * 0.2237, cornerHeight: tile * 0.2237, transform: nil))
    sheet.clip()
    // Undo the canvas flip for this draw, so the icon isn't upside down.
    sheet.translateBy(x: 0, y: rect.maxY + rect.minY)
    sheet.scaleBy(x: 1, y: -1)
    sheet.draw(image, in: rect)
    sheet.restoreGState()
}
save(sheet.makeImage()!, "concepts.png")
print("Rendered \(concepts.count) concepts to \(outDir)")
