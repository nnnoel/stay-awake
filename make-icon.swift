// Draws the Stay Awake app icon: a steaming coffee cup on an Iceberg Dark
// tile. Usage: swift make-icon.swift <out.png>  (1024x1024 PNG)
//
// Shapes are plain Bézier paths; SF Symbols aren't licensed for app icons.

import AppKit

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xff) / 255,
            green: CGFloat(hex >> 8 & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha)
}

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Tile: the standard macOS icon grid (824pt rounded square, 100pt margin).
let tileRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let tile = NSBezierPath(roundedRect: tileRect, xRadius: 185, yRadius: 185)
NSGraphicsContext.saveGraphicsState()
let tileShadow = NSShadow()
tileShadow.shadowColor = color(0x000000, 0.35)
tileShadow.shadowOffset = NSSize(width: 0, height: -12)
tileShadow.shadowBlurRadius = 28
tileShadow.set()
color(0x161821).setFill()
tile.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: color(0x2e3450), ending: color(0x161821))!.draw(in: tile, angle: -90)

// Steam: three soft S-curves rising from the cup.
for (i, x) in [432.0, 512.0, 592.0].enumerated() {
    let rise = i == 1 ? 175.0 : 140.0
    let steam = NSBezierPath()
    steam.move(to: NSPoint(x: x, y: 690))
    steam.curve(to: NSPoint(x: x, y: 690 + rise),
                controlPoint1: NSPoint(x: x + 45, y: 690 + rise * 0.35),
                controlPoint2: NSPoint(x: x - 45, y: 690 + rise * 0.65))
    steam.lineWidth = 30
    steam.lineCapStyle = .round
    color(0x89b8c2, i == 1 ? 0.95 : 0.7).setStroke()
    steam.stroke()
}

// Saucer, with a soft shadow beneath it.
NSGraphicsContext.saveGraphicsState()
let saucerShadow = NSShadow()
saucerShadow.shadowColor = color(0x000000, 0.45)
saucerShadow.shadowOffset = NSSize(width: 0, height: -10)
saucerShadow.shadowBlurRadius = 24
saucerShadow.set()
let saucer = NSBezierPath(ovalIn: NSRect(x: 252, y: 262, width: 520, height: 96))
color(0xa3a5b0).setFill()
saucer.fill()
NSGraphicsContext.restoreGraphicsState()
color(0xc6c8d1).setFill()
NSBezierPath(ovalIn: NSRect(x: 262, y: 276, width: 500, height: 78)).fill()

// Handle, drawn before the cup so the cup covers its inner end.
let handle = NSBezierPath(ovalIn: NSRect(x: 628, y: 432, width: 150, height: 170))
handle.lineWidth = 40
color(0xc6c8d1).setStroke()
handle.stroke()

// Cup body: wide rim tapering to a rounded base.
let cup = NSBezierPath()
cup.move(to: NSPoint(x: 322, y: 640))
cup.line(to: NSPoint(x: 702, y: 640))
cup.curve(to: NSPoint(x: 600, y: 318),
          controlPoint1: NSPoint(x: 702, y: 470), controlPoint2: NSPoint(x: 676, y: 330))
cup.line(to: NSPoint(x: 424, y: 318))
cup.curve(to: NSPoint(x: 322, y: 640),
          controlPoint1: NSPoint(x: 348, y: 330), controlPoint2: NSPoint(x: 322, y: 470))
cup.close()
NSGradient(colors: [color(0xa3a5b0), color(0xe8e9ee), color(0xc6c8d1)],
           atLocations: [0, 0.4, 1], colorSpace: .sRGB)!.draw(in: cup, angle: 0)

// Rim and coffee surface.
color(0xe8e9ee).setFill()
NSBezierPath(ovalIn: NSRect(x: 322, y: 608, width: 380, height: 64)).fill()
NSGradient(starting: color(0x6e4630), ending: color(0x9b6a48))!
    .draw(in: NSBezierPath(ovalIn: NSRect(x: 342, y: 616, width: 340, height: 48)), angle: 90)

// Iceberg accent band around the cup.
let band = NSBezierPath(rect: NSRect(x: 300, y: 470, width: 424, height: 34))
NSGraphicsContext.saveGraphicsState()
cup.addClip()
color(0xe2a478).setFill()
band.fill()
NSGraphicsContext.restoreGraphicsState()

NSGraphicsContext.current = nil
let out = URL(fileURLWithPath: CommandLine.arguments[1])
try rep.representation(using: .png, properties: [:])!.write(to: out)
