import Foundation

/// Настройки в общем UserDefaults App Group (видны и приложению, и расширениям).
enum AppSettings {
    enum Key {
        static let haptics = "settings.haptics"
        static let edgeGlow = "settings.edgeGlow"
        static let searchEngine = "settings.searchEngine"
        static let scanTextOnOpen = "settings.scanTextOnOpen"
    }

    private static var defaults: UserDefaults { AppGroup.defaults }

    static var hapticsEnabled: Bool { defaults.object(forKey: Key.haptics) as? Bool ?? true }
    static var edgeGlowEnabled: Bool { defaults.object(forKey: Key.edgeGlow) as? Bool ?? true }
    static var scanTextOnOpen: Bool { defaults.object(forKey: Key.scanTextOnOpen) as? Bool ?? true }

    static var searchEngine: SearchEngine {
        defaults.string(forKey: Key.searchEngine).flatMap(SearchEngine.init(rawValue:)) ?? .googleLens
    }
}
