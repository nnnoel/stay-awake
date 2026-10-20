// Draws the Stay Awake app icon: a steaming coffee cup on an Iceberg Dark
// tile. Usage: swift make-icon.swift <out.png>  (1024x1024 PNG)
//
// Shapes are plain Bézier paths; SF Symbols aren't licensed for app icons.

import AppKit

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255,
            green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha)
}

func gradient(_ colors: [CGColor], _ locations: [CGFloat]? = nil) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
               colors: colors as CFArray, locations: locations)!
}

let size = 1024
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

// Tile: the standard macOS icon grid (824pt rounded square, 100pt margin).
let tile = CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824),
                  cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.3))
ctx.addPath(tile)
ctx.setFillColor(color(0x1b1e2c))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(tile)
ctx.clip()
// Deep blue-to-ink base, then a soft glow behind the cup.
ctx.drawLinearGradient(gradient([color(0x3a4468), color(0x1b1e2c)]),
                       start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])
ctx.drawRadialGradient(gradient([color(0x84a0c6, 0.38), color(0x84a0c6, 0)]),
                       startCenter: CGPoint(x: 512, y: 560), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 560), endRadius: 400, options: [])
ctx.restoreGState()

// Steam: three thin wisps that fade out as they rise.
for (i, x) in [452.0, 512.0, 572.0].enumerated() {
    let base = 670.0, rise = i == 1 ? 190.0 : 150.0
    let wisp = CGMutablePath()
    wisp.move(to: CGPoint(x: x, y: base))
    wisp.addCurve(to: CGPoint(x: x, y: base + rise),
                  control1: CGPoint(x: x + 34, y: base + rise * 0.35),
                  control2: CGPoint(x: x - 34, y: base + rise * 0.65))
    ctx.saveGState()
    ctx.addPath(wisp.copy(strokingWithWidth: 22, lineCap: .round, lineJoin: .round, miterLimit: 1))
    ctx.clip()
    ctx.drawLinearGradient(gradient([color(0xd2e4ea, 0.9), color(0xd2e4ea, 0)]),
                           start: CGPoint(x: x, y: base), end: CGPoint(x: x, y: base + rise + 11), options: [])
    ctx.restoreGState()
}

// Saucer, with a soft shadow beneath it.
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 30, color: color(0x0b0c12, 0.55))
ctx.addEllipse(in: CGRect(x: 272, y: 282, width: 480, height: 70))
ctx.setFillColor(color(0xc9ccd8))
ctx.fillPath()
ctx.restoreGState()

// Handle, drawn before the cup so the cup covers its inner end.
ctx.addEllipse(in: CGRect(x: 630, y: 440, width: 140, height: 160))
ctx.setLineWidth(38)
ctx.setStrokeColor(color(0xdfe2ea))
ctx.strokePath()

// Cup body: wide rim tapering to a rounded base, lit softly from above.
let cup = CGMutablePath()
cup.move(to: CGPoint(x: 322, y: 640))
cup.addLine(to: CGPoint(x: 702, y: 640))
cup.addCurve(to: CGPoint(x: 600, y: 318),
             control1: CGPoint(x: 702, y: 470), control2: CGPoint(x: 676, y: 330))
cup.addLine(to: CGPoint(x: 424, y: 318))
cup.addCurve(to: CGPoint(x: 322, y: 640),
             control1: CGPoint(x: 348, y: 330), control2: CGPoint(x: 322, y: 470))
cup.closeSubpath()
ctx.saveGState()
ctx.addPath(cup)
ctx.clip()
ctx.drawLinearGradient(gradient([color(0xf7f8fb), color(0xd3d7e2)]),
                       start: CGPoint(x: 512, y: 640), end: CGPoint(x: 512, y: 318), options: [])
ctx.restoreGState()

// Rim and coffee surface.
ctx.addEllipse(in: CGRect(x: 322, y: 610, width: 380, height: 60))
ctx.setFillColor(color(0xf7f8fb))
ctx.fillPath()
ctx.addEllipse(in: CGRect(x: 340, y: 618, width: 344, height: 44))
ctx.setFillColor(color(0x7a5541))
ctx.fillPath()

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
