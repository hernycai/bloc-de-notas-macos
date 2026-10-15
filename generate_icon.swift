import AppKit

func createNotepadImage(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        img.unlockFocus()
        return img
    }
    
    let scale = size / 512.0
    
    // Draw background shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -8 * scale), blur: 16 * scale, color: NSColor.black.withAlphaComponent(0.35).cgColor)
    
    // Notebook cover / base (classic blue notepad with rounded corners)
    let padRect = CGRect(x: 60 * scale, y: 50 * scale, width: 392 * scale, height: 412 * scale)
    let padPath = NSBezierPath(roundedRect: padRect, xRadius: 28 * scale, yRadius: 28 * scale)
    
    // Windows notepad iconic blue color gradient
    let gradColors = [
        NSColor(calibratedRed: 0.12, green: 0.50, blue: 0.88, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.04, green: 0.35, blue: 0.72, alpha: 1.0).cgColor
    ] as CFArray
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: [0.0, 1.0]) {
        padPath.addClip()
        ctx.drawLinearGradient(gradient, start: CGPoint(x: padRect.midX, y: padRect.maxY), end: CGPoint(x: padRect.midX, y: padRect.minY), options: [])
    }
    ctx.restoreGState()
    
    // Notepad white paper sheet
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -4 * scale), blur: 8 * scale, color: NSColor.black.withAlphaComponent(0.2).cgColor)
    let paperRect = CGRect(x: 85 * scale, y: 75 * scale, width: 342 * scale, height: 350 * scale)
    let paperPath = NSBezierPath(roundedRect: paperRect, xRadius: 16 * scale, yRadius: 16 * scale)
    NSColor.white.setFill()
    paperPath.fill()
    ctx.restoreGState()
    
    // Draw notebook ruling lines (classic faint blue lines)
    ctx.saveGState()
    let lineColor = NSColor(calibratedRed: 0.82, green: 0.88, blue: 0.95, alpha: 1.0)
    lineColor.setStroke()
    let lineWidth: CGFloat = max(1.0, 2.5 * scale)
    
    var y = paperRect.maxY - (45 * scale)
    while y > paperRect.minY + (35 * scale) {
        let p = NSBezierPath()
        p.move(to: NSPoint(x: paperRect.minX + (25 * scale), y: y))
        p.line(to: NSPoint(x: paperRect.maxX - (25 * scale), y: y))
        p.lineWidth = lineWidth
        p.stroke()
        y -= 28 * scale
    }
    
    // Red margin line on the left
    let redMargin = NSColor(calibratedRed: 0.95, green: 0.45, blue: 0.45, alpha: 0.75)
    redMargin.setStroke()
    let marginPath = NSBezierPath()
    marginPath.move(to: NSPoint(x: paperRect.minX + 50 * scale, y: paperRect.minY + 20 * scale))
    marginPath.line(to: NSPoint(x: paperRect.minX + 50 * scale, y: paperRect.maxY - 20 * scale))
    marginPath.lineWidth = max(1.0, 2.0 * scale)
    marginPath.stroke()
    ctx.restoreGState()
    
    // Spiral rings or top binding
    ctx.saveGState()
    let bindingColor = NSColor(calibratedWhite: 0.85, alpha: 1.0)
    let ringHoleColor = NSColor(calibratedWhite: 0.25, alpha: 0.6)
    for i in 0..<8 {
        let x = paperRect.minX + 35 * scale + CGFloat(i) * (38 * scale)
        let ringRect = CGRect(x: x, y: paperRect.maxY - 14 * scale, width: 14 * scale, height: 26 * scale)
        
        // Ring hole
        let holePath = NSBezierPath(ovalIn: CGRect(x: x + 2 * scale, y: paperRect.maxY - 10 * scale, width: 10 * scale, height: 10 * scale))
        ringHoleColor.setFill()
        holePath.fill()
        
        // Metallic spiral ring
        let ringPath = NSBezierPath(roundedRect: ringRect, xRadius: 6 * scale, yRadius: 6 * scale)
        ringPath.lineWidth = 3.5 * scale
        bindingColor.setStroke()
        ringPath.stroke()
    }
    ctx.restoreGState()
    
    // Classic Windows Notepad pencil angled at the bottom right
    ctx.saveGState()
    ctx.translateBy(x: 340 * scale, y: 160 * scale)
    ctx.rotate(by: 42.0 * .pi / 180.0)
    ctx.setShadow(offset: CGSize(width: -6 * scale, height: -6 * scale), blur: 10 * scale, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    
    // Pencil body (yellow)
    let pencilBody = NSBezierPath(roundedRect: CGRect(x: -12 * scale, y: 0, width: 24 * scale, height: 180 * scale), xRadius: 4 * scale, yRadius: 4 * scale)
    NSColor(calibratedRed: 0.98, green: 0.76, blue: 0.15, alpha: 1.0).setFill()
    pencilBody.fill()
    
    // Pencil stripes
    let pencilStripe = NSBezierPath(rect: CGRect(x: -4 * scale, y: 0, width: 8 * scale, height: 180 * scale))
    NSColor(calibratedRed: 0.92, green: 0.68, blue: 0.10, alpha: 1.0).setFill()
    pencilStripe.fill()
    
    // Pencil ferrule (metal silver ring)
    let ferrule = NSBezierPath(rect: CGRect(x: -12 * scale, y: 180 * scale, width: 24 * scale, height: 25 * scale))
    NSColor(calibratedWhite: 0.8, alpha: 1.0).setFill()
    ferrule.fill()
    
    // Pencil eraser (pink)
    let eraser = NSBezierPath(roundedRect: CGRect(x: -12 * scale, y: 205 * scale, width: 24 * scale, height: 28 * scale), xRadius: 5 * scale, yRadius: 5 * scale)
    NSColor(calibratedRed: 0.95, green: 0.55, blue: 0.60, alpha: 1.0).setFill()
    eraser.fill()
    
    // Pencil wood tip
    let tip = NSBezierPath()
    tip.move(to: NSPoint(x: -12 * scale, y: 0))
    tip.line(to: NSPoint(x: 12 * scale, y: 0))
    tip.line(to: NSPoint(x: 0, y: -35 * scale))
    tip.close()
    NSColor(calibratedRed: 0.92, green: 0.82, blue: 0.68, alpha: 1.0).setFill()
    tip.fill()
    
    // Graphite lead tip
    let lead = NSBezierPath()
    lead.move(to: NSPoint(x: -4 * scale, y: -18 * scale))
    lead.line(to: NSPoint(x: 4 * scale, y: -18 * scale))
    lead.line(to: NSPoint(x: 0, y: -35 * scale))
    lead.close()
    NSColor(calibratedWhite: 0.15, alpha: 1.0).setFill()
    lead.fill()
    
    ctx.restoreGState()
    
    img.unlockFocus()
    return img
}

let fm = FileManager.default
let iconsetDir = "AppIcon.iconset"
try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = createNotepadImage(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: "\(iconsetDir)/\(name)")
        try? png.write(to: url)
    }
}

print("Iconset generated successfully!")
