import AppKit

struct MenuItemModel {
    let title: String
    let shortcut: String
    let isSeparator: Bool
    let isChecked: Bool
    let isEnabled: Bool
    let action: (() -> Void)?
    
    static func item(_ title: String, shortcut: String = "", isChecked: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) -> MenuItemModel {
        return MenuItemModel(title: title, shortcut: shortcut, isSeparator: false, isChecked: isChecked, isEnabled: isEnabled, action: action)
    }
    
    static func separator() -> MenuItemModel {
        return MenuItemModel(title: "", shortcut: "", isSeparator: true, isChecked: false, isEnabled: false, action: nil)
    }
}

protocol WindowsDropdownViewDelegate: AnyObject {
    func dropdownDidSelectItem(_ item: MenuItemModel)
    func dropdownDidRequestNavigate(left: Bool)
    func dropdownDidRequestDismiss()
}

class WindowsDropdownView: NSView {
    weak var delegate: WindowsDropdownViewDelegate?
    
    var items: [MenuItemModel] = [] {
        didSet {
            hoveredIndex = -1
            updateTrackingAreas()
            needsDisplay = true
        }
    }
    
    var hoveredIndex: Int = -1 {
        didSet {
            if oldValue != hoveredIndex {
                needsDisplay = true
            }
        }
    }
    
    let itemHeight: CGFloat = 26.0
    let separatorHeight: CGFloat = 7.0
    
    override var isFlipped: Bool { return true }
    
    func calculateTotalHeight() -> CGFloat {
        var h: CGFloat = 8.0 // top & bottom padding
        for item in items {
            h += item.isSeparator ? separatorHeight : itemHeight
        }
        return h
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let area = NSTrackingArea(rect: bounds, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(area)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let newIndex = itemIndex(at: point)
        if newIndex != hoveredIndex {
            if newIndex >= 0 && newIndex < items.count && !items[newIndex].isSeparator && items[newIndex].isEnabled {
                hoveredIndex = newIndex
            } else {
                hoveredIndex = -1
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        hoveredIndex = -1
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let idx = itemIndex(at: point)
        if idx >= 0 && idx < items.count {
            let item = items[idx]
            if !item.isSeparator && item.isEnabled {
                delegate?.dropdownDidSelectItem(item)
            }
        }
    }
    
    private func itemIndex(at point: NSPoint) -> Int {
        var y: CGFloat = 4.0
        for (i, item) in items.enumerated() {
            let h = item.isSeparator ? separatorHeight : itemHeight
            if point.y >= y && point.y < y + h {
                return i
            }
            y += h
        }
        return -1
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let isDark = ThemeManager.shared.isDark
        let bgColor = isDark ? NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.19, alpha: 1.0) : NSColor.white
        let borderColor = isDark ? NSColor(calibratedWhite: 0.35, alpha: 1.0) : NSColor(calibratedWhite: 0.80, alpha: 1.0)
        let textColor = isDark ? NSColor(calibratedWhite: 0.95, alpha: 1.0) : NSColor(calibratedWhite: 0.10, alpha: 1.0)
        let disabledColor = isDark ? NSColor(calibratedWhite: 0.50, alpha: 1.0) : NSColor(calibratedWhite: 0.60, alpha: 1.0)
        let shortcutColor = isDark ? NSColor(calibratedWhite: 0.65, alpha: 1.0) : NSColor(calibratedWhite: 0.45, alpha: 1.0)
        let hoverBgColor = isDark ? NSColor(calibratedRed: 0.22, green: 0.38, blue: 0.60, alpha: 1.0) : NSColor(calibratedRed: 0.82, green: 0.90, blue: 0.98, alpha: 1.0)
        
        // Background
        bgColor.setFill()
        bounds.fill()
        
        // Border
        borderColor.setStroke()
        let borderPath = NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5))
        borderPath.lineWidth = 1.0
        borderPath.stroke()
        
        var y: CGFloat = 4.0
        let font = ThemeManager.shared.uiFont(size: 12)
        let shortcutFont = ThemeManager.shared.uiFont(size: 11)
        
        for (i, item) in items.enumerated() {
            if item.isSeparator {
                let sepY = y + (separatorHeight / 2)
                let sepColor = isDark ? NSColor(calibratedWhite: 0.28, alpha: 1.0) : NSColor(calibratedWhite: 0.88, alpha: 1.0)
                sepColor.setStroke()
                let sep = NSBezierPath()
                sep.move(to: NSPoint(x: 8, y: sepY))
                sep.line(to: NSPoint(x: bounds.width - 8, y: sepY))
                sep.lineWidth = 1.0
                sep.stroke()
                y += separatorHeight
            } else {
                let rowRect = NSRect(x: 3, y: y, width: bounds.width - 6, height: itemHeight)
                
                // Hover highlight
                if i == hoveredIndex && item.isEnabled {
                    hoverBgColor.setFill()
                    let hoverPath = NSBezierPath(roundedRect: rowRect, xRadius: 3, yRadius: 3)
                    hoverPath.fill()
                }
                
                // Checkmark
                if item.isChecked {
                    let checkStr = "✓" as NSString
                    let checkAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.boldSystemFont(ofSize: 13),
                        .foregroundColor: item.isEnabled ? textColor : disabledColor
                    ]
                    checkStr.draw(at: NSPoint(x: 10, y: y + 4), withAttributes: checkAttrs)
                }
                
                // Title
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: item.isEnabled ? textColor : disabledColor
                ]
                (item.title as NSString).draw(at: NSPoint(x: 28, y: y + 5), withAttributes: titleAttrs)
                
                // Shortcut
                if !item.shortcut.isEmpty {
                    let scAttrs: [NSAttributedString.Key: Any] = [
                        .font: shortcutFont,
                        .foregroundColor: item.isEnabled ? shortcutColor : disabledColor
                    ]
                    let scSize = (item.shortcut as NSString).size(withAttributes: scAttrs)
                    (item.shortcut as NSString).draw(at: NSPoint(x: bounds.width - scSize.width - 16, y: y + 6), withAttributes: scAttrs)
                }
                
                y += itemHeight
            }
        }
    }
}

class WindowsDropdownPanel: NSPanel, WindowsDropdownViewDelegate {
    private let dropdownView = WindowsDropdownView()
    var onDismiss: (() -> Void)?
    var onNavigate: ((Bool) -> Void)?
    
    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 220, height: 200),
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .floating
        self.isMovable = false
        
        dropdownView.delegate = self
        self.contentView = dropdownView
    }
    
    func show(items: [MenuItemModel], at screenOrigin: NSPoint, width: CGFloat = 220) {
        dropdownView.items = items
        let totalH = dropdownView.calculateTotalHeight()
        
        let frame = NSRect(x: screenOrigin.x, y: screenOrigin.y - totalH, width: width, height: totalH)
        self.setFrame(frame, display: true)
        self.dropdownView.frame = NSRect(x: 0, y: 0, width: width, height: totalH)
        self.dropdownView.updateTrackingAreas()
        
        self.orderFront(nil)
    }
    
    func dismiss() {
        self.orderOut(nil)
        onDismiss?()
    }
    
    // MARK: - WindowsDropdownViewDelegate
    
    func dropdownDidSelectItem(_ item: MenuItemModel) {
        dismiss()
        item.action?()
    }
    
    func dropdownDidRequestNavigate(left: Bool) {
        onNavigate?(left)
    }
    
    func dropdownDidRequestDismiss() {
        dismiss()
    }
}
