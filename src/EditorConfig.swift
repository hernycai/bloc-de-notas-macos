import AppKit

extension Notification.Name {
    static let editorConfigDidChange = Notification.Name("editorConfigDidChange")
}

class EditorConfig {
    static let shared = EditorConfig()
    
    private let kThemeMode = "config_theme_mode"
    private let kFontFamily = "config_default_font_family"
    private let kFontSize = "config_default_font_size"
    private let kWordWrap = "config_default_word_wrap"
    private let kLineEnding = "config_default_line_ending"
    private let kEncoding = "config_default_encoding"
    private let kShowFormatBar = "config_show_format_bar"
    private let kShowStatusBar = "config_show_status_bar"
    
    var themeMode: NotepadThemeMode {
        get {
            let val = UserDefaults.standard.string(forKey: kThemeMode) ?? "system"
            return NotepadThemeMode(rawValue: val) ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: kThemeMode)
            ThemeManager.shared.currentMode = newValue
            notifyChange()
        }
    }
    
    var defaultFontFamily: String {
        get {
            return UserDefaults.standard.string(forKey: kFontFamily) ?? "Consolas"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kFontFamily)
            notifyChange()
        }
    }
    
    var defaultFontSize: CGFloat {
        get {
            let val = UserDefaults.standard.double(forKey: kFontSize)
            return val > 0 ? CGFloat(val) : 14.0
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: kFontSize)
            notifyChange()
        }
    }
    
    var defaultWordWrap: Bool {
        get {
            if UserDefaults.standard.object(forKey: kWordWrap) == nil { return true }
            return UserDefaults.standard.bool(forKey: kWordWrap)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kWordWrap)
            notifyChange()
        }
    }
    
    var defaultLineEnding: LineEnding {
        get {
            let val = UserDefaults.standard.string(forKey: kLineEnding) ?? "crlf"
            return val == "lf" ? .lf : .crlf
        }
        set {
            UserDefaults.standard.set(newValue == .lf ? "lf" : "crlf", forKey: kLineEnding)
            notifyChange()
        }
    }
    
    var defaultEncoding: String.Encoding {
        get {
            let val = UserDefaults.standard.string(forKey: kEncoding) ?? "utf8"
            if val == "windows1252" { return .windowsCP1252 }
            return .utf8
        }
        set {
            UserDefaults.standard.set(newValue == .windowsCP1252 ? "windows1252" : "utf8", forKey: kEncoding)
            notifyChange()
        }
    }
    
    var showFormatBarByDefault: Bool {
        get {
            if UserDefaults.standard.object(forKey: kShowFormatBar) == nil { return true }
            return UserDefaults.standard.bool(forKey: kShowFormatBar)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kShowFormatBar)
            notifyChange()
        }
    }
    
    var showStatusBarByDefault: Bool {
        get {
            if UserDefaults.standard.object(forKey: kShowStatusBar) == nil { return true }
            return UserDefaults.standard.bool(forKey: kShowStatusBar)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: kShowStatusBar)
            notifyChange()
        }
    }
    
    private func notifyChange() {
        NotificationCenter.default.post(name: .editorConfigDidChange, object: nil)
    }
}
