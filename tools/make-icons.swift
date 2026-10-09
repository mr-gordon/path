// Erzeugt Resources/AppIcon.icns und Resources/MenuBarIcon.png
// Aufruf: swift tools/make-icons.swift
import AppKit

/// Das Pfad-Symbol: Startpunkt, geschwungene Route, Pfeilspitze. Koordinaten 0...1.
func drawGlyph(in ctx: CGContext, size: CGFloat, origin: CGPoint = .zero, color: NSColor, weight: CGFloat) {
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: origin.x + x * size, y: origin.y + y * size) }
    ctx.setStrokeColor(color.cgColor)
    ctx.setFillColor(color.cgColor)
    ctx.setLineWidth(weight * size)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    ctx.move(to: p(0.22, 0.28))
    ctx.addCurve(to: p(0.56, 0.72), control1: p(0.42, 0.28), control2: p(0.36, 0.72))
    ctx.addLine(to: p(0.80, 0.72))
    ctx.strokePath()

    ctx.move(to: p(0.66, 0.85))
    ctx.addLine(to: p(0.80, 0.72))
    ctx.addLine(to: p(0.66, 0.59))
    ctx.strokePath()

    let r = weight * size * 0.85
    ctx.fillEllipse(in: CGRect(x: p(0.22, 0.28).x - r, y: p(0.22, 0.28).y - r, width: 2 * r, height: 2 * r))
}

func render(_ px: Int, _ draw: (CGContext, CGFloat) -> Void) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = gc
    draw(gc.cgContext, CGFloat(px))
    return rep.representation(using: .png, properties: [:])!
}

func appIcon(_ ctx: CGContext, _ s: CGFloat) {
    let inset = s * 0.0977
    let rect = CGRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let shape = CGPath(roundedRect: rect, cornerWidth: rect.width * 0.2237, cornerHeight: rect.width * 0.2237, transform: nil)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.02, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    ctx.addPath(shape); ctx.setFillColor(NSColor.black.cgColor); ctx.fillPath()
    ctx.restoreGState()
    ctx.saveGState()
    ctx.addPath(shape); ctx.clip()
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [NSColor(red: 0.32, green: 0.78, blue: 0.95, alpha: 1).cgColor,
                                   NSColor(red: 0.10, green: 0.32, blue: 0.85, alpha: 1).cgColor] as CFArray,
                          locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s - inset), end: CGPoint(x: s, y: inset), options: [])
    ctx.restoreGState()
    let g = rect.width * 0.82
    drawGlyph(in: ctx, size: g, origin: CGPoint(x: rect.midX - g / 2, y: rect.midY - g / 2), color: .white, weight: 0.07)
}

let fm = FileManager.default
let iconset = "build/AppIcon.iconset"
try? fm.removeItem(atPath: iconset)
try! fm.createDirectory(atPath: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        try! render(base * scale, appIcon).write(to: URL(fileURLWithPath: "\(iconset)/\(name)"))
    }
}
// Menüleiste: schwarzes Template-Bild, 18 pt @2x
try! render(36) { ctx, s in
    drawGlyph(in: ctx, size: s * 0.92, origin: CGPoint(x: s * 0.04, y: s * 0.04), color: .black, weight: 0.095)
}.write(to: URL(fileURLWithPath: "Resources/MenuBarIcon.png"))
