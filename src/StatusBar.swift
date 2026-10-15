import AppKit

class StatusBar: NSView {
    private let cursorLabel = NSTextField(labelWithString: "  Lín 1, Col 1")
    private let zoomLabel = NSTextField(labelWithString: "100%")
    private let lineEndingLabel = NSTextField(labelWithString: "Windows (CRLF)")
    private let encodingLabel = NSTextField(labelWithString: "UTF-8")
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = ThemeManager.shared.statusBarBackgroundColor.cgColor
        
        let labels = [cursorLabel, zoomLabel, lineEndingLabel, encodingLabel]
        for label in labels {
            label.font = ThemeManager.shared.uiFont(size: 11)
            label.textColor = ThemeManager.shared.statusBarTextColor
            label.isBordered = false
            label.isBezeled = false
            label.isEditable = false
            label.isSelectable = false
            label.backgroundColor = .clear
            label.alignment = .left
            addSubview(label)
        }
        
        zoomLabel.alignment = .center
        lineEndingLabel.alignment = .center
        encodingLabel.alignment = .center
    }
    
    func applyTheme() {
        layer?.backgroundColor = ThemeManager.shared.statusBarBackgroundColor.cgColor
        let labels = [cursorLabel, zoomLabel, lineEndingLabel, encodingLabel]
        for label in labels {
            label.textColor = ThemeManager.shared.statusBarTextColor
        }
        needsDisplay = true
    }
    
    func setCursorPosition(line: Int, column: Int) {
        cursorLabel.stringValue = "  Lín \(line), Col \(column)"
    }
    
    func setZoom(percentage: Int) {
        zoomLabel.stringValue = "\(percentage)%"
    }
    
    func setLineEnding(_ ending: LineEnding) {
        lineEndingLabel.stringValue = ending.rawValue
    }
    
    func setEncoding(_ encodingName: String) {
        encodingLabel.stringValue = encodingName
    }
    
    override func layout() {
        super.layout()
        let h = bounds.height
        let w = bounds.width
        
        let encW: CGFloat = 100
        let leW: CGFloat = 130
        let zoomW: CGFloat = 70
        let cursorW: CGFloat = max(100, w - encW - leW - zoomW)
        
        cursorLabel.frame = NSRect(x: 0, y: 3, width: cursorW, height: h - 6)
        zoomLabel.frame = NSRect(x: cursorW, y: 3, width: zoomW, height: h - 6)
        lineEndingLabel.frame = NSRect(x: cursorW + zoomW, y: 3, width: leW, height: h - 6)
        encodingLabel.frame = NSRect(x: cursorW + zoomW + leW, y: 3, width: encW, height: h - 6)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.saveGState()
        
        // Top border
        ThemeManager.shared.separatorColor.setStroke()
        let topBorder = NSBezierPath()
        topBorder.move(to: NSPoint(x: 0, y: bounds.height - 0.5))
        topBorder.line(to: NSPoint(x: bounds.width, y: bounds.height - 0.5))
        topBorder.lineWidth = 1.0
        topBorder.stroke()
        
        // Vertical separators between segments
        let encW: CGFloat = 100
        let leW: CGFloat = 130
        let zoomW: CGFloat = 70
        let cursorW: CGFloat = max(100, bounds.width - encW - leW - zoomW)
        
        let divX1 = cursorW
        let divX2 = cursorW + zoomW
        let divX3 = cursorW + zoomW + leW
        
        for x in [divX1, divX2, divX3] {
            let p = NSBezierPath()
            p.move(to: NSPoint(x: x + 0.5, y: 2))
            p.line(to: NSPoint(x: x + 0.5, y: bounds.height - 3))
            p.lineWidth = 1.0
            p.stroke()
        }
        
        ctx?.restoreGState()
    }
}
