import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import SwiftUI // only for Apple's continuous ("squircle") corners, which the screens have

// Frames the README screenshots as an iPhone and an Apple Watch Ultra, and renders the
// hero image with both, from plain CoreGraphics shapes.
//
//   swift Design/render-readme-images.swift <screenshots folder> docs/images
//
// The screenshots come from the simulators with the app in demo mode (see the README):
//   iphone-radar.png, iphone-dynamic-island.png, iphone-settings.png   iPhone 18 Pro, 1206×2622
//   watch-ride.png, watch-car-alert.png                                Watch Ultra 2, 410×502

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    print("usage: swift Design/render-readme-images.swift <screenshots folder> <output folder>")
    exit(1)
}
let inDir = URL(fileURLWithPath: arguments[1])
let outDir = URL(fileURLWithPath: arguments[2])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: sRGB, components: [CGFloat((hex >> 16) & 0xFF) / 255,
                                           CGFloat((hex >> 8) & 0xFF) / 255,
                                           CGFloat(hex & 0xFF) / 255, alpha])!
}

let red: UInt32 = 0xFF3B30
let titanium = [rgb(0xD1D1D6), rgb(0x8E8E93), rgb(0x4A4A4F)]

/// A transparent canvas with y growing downward, like a design tool.
func canvas(_ width: Int, _ height: Int) -> CGContext {
    let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                        space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1, y: -1)
    ctx.interpolationQuality = .high
    return ctx
}

func load(_ name: String) -> CGImage {
    let url = inDir.appendingPathComponent(name)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        print("missing \(url.path)")
        exit(1)
    }
    return image
}

func save(_ ctx: CGContext, _ name: String) {
    let url = outDir.appendingPathComponent(name)
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    print("wrote \(url.path)")
}

// MARK: Shapes

func squircle(_ rect: CGRect, _ radius: CGFloat) -> CGPath {
    RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect).cgPath
}

func pill(_ rect: CGRect) -> CGPath {
    let radius = min(rect.width, rect.height) / 2
    return CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func fill(_ path: CGPath, _ ctx: CGContext, _ color: CGColor) {
    ctx.addPath(path)
    ctx.setFillColor(color)
    ctx.fillPath()
}

func fill(_ path: CGPath, _ ctx: CGContext, _ colors: [CGColor], from start: CGPoint, to end: CGPoint) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: sRGB, colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(gradient, start: start, end: end,
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

/// Titanium lit from the top left.
func metal(_ path: CGPath, _ ctx: CGContext) {
    let box = path.boundingBox
    fill(path, ctx, titanium, from: box.origin, to: CGPoint(x: box.maxX, y: box.maxY))
}

/// A soft shadow falling below `path`. (Shadows ignore the flipped canvas, so "down"
/// is a negative offset.)
func shadow(_ path: CGPath, _ ctx: CGContext, blur: CGFloat) {
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -blur * 0.4), blur: blur, color: rgb(0x000000, 0.55))
    fill(path, ctx, rgb(0x000000))
    ctx.restoreGState()
}

func glow(_ ctx: CGContext, at center: CGPoint, radius: CGFloat, _ hex: UInt32, _ alpha: CGFloat) {
    let gradient = CGGradient(colorsSpace: sRGB, colors: [rgb(hex, alpha), rgb(hex, 0)] as CFArray, locations: nil)!
    ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
}

/// Draws a screenshot the right way up (the canvas is flipped), clipped to the screen's corners.
func screenshot(_ image: CGImage, in rect: CGRect, radius: CGFloat, _ ctx: CGContext) {
    ctx.saveGState()
    ctx.addPath(squircle(rect, radius))
    ctx.clip()
    ctx.translateBy(x: rect.minX, y: rect.maxY)
    ctx.scaleBy(x: 1, y: -1)
    ctx.draw(image, in: CGRect(origin: .zero, size: rect.size))
    ctx.restoreGState()
}

// MARK: iPhone

/// iPhone 18 Pro, in its screen's pixels (3×): 62 pt continuous screen corners.
enum Phone {
    static let screen = CGSize(width: 1206, height: 2622)
    static let screenRadius: CGFloat = 186
    static let glass: CGFloat = 30  // black border around the screen
    static let rim: CGFloat = 22    // titanium band
    static let outset = glass + rim
}

/// A phone whose screen fills `screen`.
func drawPhone(_ shot: CGImage, screen: CGRect, _ ctx: CGContext) {
    let k = screen.width / Phone.screen.width
    let body = screen.insetBy(dx: -Phone.outset * k, dy: -Phone.outset * k)

    // Buttons first; the body covers their inner half.
    func button(left: Bool, top: CGFloat, length: CGFloat) {
        let x = left ? body.minX - 12 * k : body.maxX - 12 * k
        metal(pill(CGRect(x: x, y: body.minY + top * k, width: 24 * k, height: length * k)), ctx)
    }
    button(left: true, top: 560, length: 190)    // Action button
    button(left: true, top: 880, length: 300)    // volume up
    button(left: true, top: 1240, length: 300)   // volume down
    button(left: false, top: 1000, length: 440)  // side button

    let bodyPath = squircle(body, (Phone.screenRadius + Phone.outset) * k)
    shadow(bodyPath, ctx, blur: 90 * k)
    metal(bodyPath, ctx)
    let glass = screen.insetBy(dx: -Phone.glass * k, dy: -Phone.glass * k)
    fill(squircle(glass, (Phone.screenRadius + Phone.glass) * k), ctx, rgb(0x000000))
    screenshot(shot, in: screen, radius: Phone.screenRadius * k, ctx)
}

// MARK: Apple Watch Ultra

/// Apple Watch Ultra 2, in its screen's pixels.
enum Watch {
    static let screen = CGSize(width: 410, height: 502)
    static let screenRadius: CGFloat = 104
    static let glass: CGFloat = 32
    static let rim: CGFloat = 40
    static let outset = glass + rim
}

/// A band filling `rect` (it starts under the case), solid up to the height `solid`
/// and faded away by the height `gone`.
func band(_ rect: CGRect, solid: CGFloat, gone: CGFloat, _ ctx: CGContext) {
    ctx.saveGState()
    ctx.beginTransparencyLayer(auxiliaryInfo: nil)
    fill(CGPath(rect: rect, transform: nil), ctx, [rgb(0x202024), rgb(0x505058), rgb(0x202024)],
         from: CGPoint(x: rect.minX, y: 0), to: CGPoint(x: rect.maxX, y: 0))
    ctx.setBlendMode(.destinationIn)
    let fade = CGGradient(colorsSpace: sRGB, colors: [rgb(0x000000), rgb(0x000000, 0)] as CFArray, locations: nil)!
    ctx.drawLinearGradient(fade, start: CGPoint(x: 0, y: solid), end: CGPoint(x: 0, y: gone),
                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.endTransparencyLayer()
    ctx.restoreGState()
}

/// A watch whose screen fills `screen`, with its bands reaching to `bandTop` and `bandBottom`.
func drawWatch(_ shot: CGImage, screen: CGRect, bandTop: CGFloat, bandBottom: CGFloat, _ ctx: CGContext) {
    let k = screen.width / Watch.screen.width
    let body = screen.insetBy(dx: -Watch.outset * k, dy: -Watch.outset * k)

    // Solid for the first 40% of the way out from the case, then fading.
    let bandX = body.midX - body.width * 0.31, bandWidth = body.width * 0.62
    band(CGRect(x: bandX, y: bandTop, width: bandWidth, height: body.midY - bandTop),
         solid: body.minY - 0.4 * (body.minY - bandTop), gone: bandTop, ctx)
    band(CGRect(x: bandX, y: body.midY, width: bandWidth, height: bandBottom - body.midY),
         solid: body.maxY + 0.4 * (bandBottom - body.maxY), gone: bandBottom, ctx)

    // The orange Action button on the left; on the right, the crown guard with the
    // Digital Crown and the side button.
    let action = CGRect(x: body.minX - 20 * k, y: body.minY + 150 * k, width: 40 * k, height: 130 * k)
    fill(pill(action), ctx, [rgb(0xFF8A4C), rgb(0xE8491D)],
         from: CGPoint(x: action.minX, y: 0), to: CGPoint(x: action.maxX, y: 0))
    let guardRect = CGRect(x: body.maxX - 40 * k, y: body.minY + 120 * k, width: 64 * k, height: 400 * k)
    let crown = CGRect(x: guardRect.maxX - 16 * k, y: body.minY + 172 * k, width: 52 * k, height: 150 * k)
    metal(squircle(crown, 14 * k), ctx)
    ctx.setStrokeColor(rgb(0x2C2C30, 0.7))
    ctx.setLineWidth(3 * k)
    for y in stride(from: crown.minY + 16 * k, to: crown.maxY - 10 * k, by: 12 * k) {
        ctx.move(to: CGPoint(x: crown.minX + 20 * k, y: y))
        ctx.addLine(to: CGPoint(x: crown.maxX - 4 * k, y: y))
    }
    ctx.strokePath()
    metal(pill(CGRect(x: guardRect.maxX - 16 * k, y: body.minY + 372 * k, width: 30 * k, height: 118 * k)), ctx)
    metal(squircle(guardRect, 30 * k), ctx)

    let bodyPath = squircle(body, (Watch.screenRadius + Watch.outset) * k)
    shadow(bodyPath, ctx, blur: 70 * k)
    metal(bodyPath, ctx)
    let glass = screen.insetBy(dx: -Watch.glass * k, dy: -Watch.glass * k)
    fill(squircle(glass, (Watch.screenRadius + Watch.glass) * k), ctx, rgb(0x000000))
    screenshot(shot, in: screen, radius: Watch.screenRadius * k, ctx)
}

// MARK: Images

/// A framed phone on a transparent background, for the screenshot table.
func savePhone(_ shotName: String) {
    let k: CGFloat = 0.4
    let size = CGSize(width: Phone.screen.width * k, height: Phone.screen.height * k)
    let outset = Phone.outset * k, margin: CGFloat = 50
    let ctx = canvas(Int(size.width + 2 * (outset + margin)), Int(size.height + 2 * outset + 2.4 * margin))
    drawPhone(load(shotName), screen: CGRect(origin: CGPoint(x: margin + outset, y: 0.8 * margin + outset), size: size), ctx)
    save(ctx, shotName)
}

/// A framed watch on a transparent background, for the screenshot table.
func saveWatch(_ shotName: String) {
    let outset = Watch.outset, margin: CGFloat = 90, bandLength: CGFloat = 170
    let width = Int(Watch.screen.width + 2 * (outset + margin)), height = Int(Watch.screen.height + 2 * (outset + bandLength))
    let ctx = canvas(width, height)
    let screen = CGRect(origin: CGPoint(x: margin + outset, y: bandLength + outset), size: Watch.screen)
    drawWatch(load(shotName), screen: screen, bandTop: 0, bandBottom: CGFloat(height), ctx)
    save(ctx, shotName)
}

// The hero: a car closing in fast, on the phone and on the wrist.
do {
    let size = CGSize(width: 1800, height: 1160)
    let ctx = canvas(Int(size.width), Int(size.height))
    let card = squircle(CGRect(origin: .zero, size: size), 64)
    ctx.addPath(card)
    ctx.clip()
    fill(card, ctx, [rgb(0x17171D), rgb(0x08080B)], from: .zero, to: CGPoint(x: 0, y: size.height))

    let phoneHeight: CGFloat = 940
    let phone = CGRect(x: 532 - phoneHeight * Phone.screen.width / Phone.screen.height / 2, y: (size.height - phoneHeight) / 2,
                       width: phoneHeight * Phone.screen.width / Phone.screen.height, height: phoneHeight)
    let watch = CGRect(origin: CGPoint(x: 1172 - Watch.screen.width / 2, y: 580 - Watch.screen.height / 2), size: Watch.screen)
    glow(ctx, at: CGPoint(x: phone.midX, y: phone.midY), radius: 680, red, 0.30)
    glow(ctx, at: CGPoint(x: watch.midX, y: watch.midY), radius: 420, red, 0.14)
    drawPhone(load("iphone-radar.png"), screen: phone, ctx)
    drawWatch(load("watch-car-alert.png"), screen: watch, bandTop: 0, bandBottom: size.height, ctx)
    save(ctx, "hero.png")
}

["iphone-radar.png", "iphone-dynamic-island.png", "iphone-settings.png"].forEach(savePhone)
["watch-ride.png", "watch-car-alert.png"].forEach(saveWatch)
