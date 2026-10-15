import AppKit

enum NotepadThemeMode: String {
    case classicLight = "light"
    case dark = "dark"
    case system = "system"
}

class ThemeManager {
    static let shared = ThemeManager()
    
    var currentMode: NotepadThemeMode {
        get {
            let val = UserDefaults.standard.string(forKey: "notepad_theme_mode") ?? "light"
            return NotepadThemeMode(rawValue: val) ?? .classicLight
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "notepad_theme_mode")
        }
    }
    
    var isDark: Bool {
        switch currentMode {
        case .classicLight:
            return false
        case .dark:
            return true
        case .system:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }
    
    func toggleTheme() {
        if isDark {
            currentMode = .classicLight
        } else {
            currentMode = .dark
        }
    }
    
    var editorBackgroundColor: NSColor {
        return isDark ? NSColor(calibratedRed: 0.12, green: 0.12, blue: 0.13, alpha: 1.0) : .white
    }
    
    var editorTextColor: NSColor {
        return isDark ? NSColor(calibratedRed: 0.94, green: 0.94, blue: 0.95, alpha: 1.0) : .black
    }
    
    var editorInsertionPointColor: NSColor {
        return isDark ? .white : .black
    }
    
    var menuBarBackgroundColor: NSColor {
        return isDark ? NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.19, alpha: 1.0) : NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
    }
    
    var menuBarTextColor: NSColor {
        return isDark ? NSColor(calibratedWhite: 0.92, alpha: 1.0) : NSColor(calibratedWhite: 0.12, alpha: 1.0)
    }
    
    var menuBarHoverColor: NSColor {
        return isDark ? NSColor(calibratedWhite: 0.28, alpha: 1.0) : NSColor(calibratedRed: 0.88, green: 0.92, blue: 0.98, alpha: 1.0)
    }
    
    var separatorColor: NSColor {
        return isDark ? NSColor(calibratedWhite: 0.26, alpha: 1.0) : NSColor(calibratedWhite: 0.82, alpha: 1.0)
    }
    
    var statusBarBackgroundColor: NSColor {
        return isDark ? NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.16, alpha: 1.0) : NSColor(calibratedRed: 0.94, green: 0.94, blue: 0.95, alpha: 1.0)
    }
    
    var statusBarTextColor: NSColor {
        return isDark ? NSColor(calibratedWhite: 0.82, alpha: 1.0) : NSColor(calibratedWhite: 0.22, alpha: 1.0)
    }
    
    var panelBackgroundColor: NSColor {
        return isDark ? NSColor(calibratedRed: 0.18, green: 0.18, blue: 0.19, alpha: 1.0) : NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
    }
    
    func editorFont(size: CGFloat) -> NSFont {
        if let font = NSFont(name: "Consolas", size: size) {
            return font
        }
        if let font = NSFont(name: "Menlo", size: size) {
            return font
        }
        if let font = NSFont(name: "Courier New", size: size) {
            return font
        }
        return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
    
    func uiFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        if let font = NSFont(name: "Segoe UI", size: size) {
            return font
        }
        return NSFont.systemFont(ofSize: size, weight: weight)
    }
}
