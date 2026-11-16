import Foundation

/// Настройки в общем UserDefaults App Group (видны и приложению, и расширениям).
public enum AppSettings {
    public enum Key {
        public static let haptics = "settings.haptics"
        public static let edgeGlow = "settings.edgeGlow"
        public static let searchEngine = "settings.searchEngine"
        public static let scanTextOnOpen = "settings.scanTextOnOpen"
        public static let autoOpenRecent = "settings.autoOpenRecent"
    }

    private static var defaults: UserDefaults { AppGroup.defaults }

    static var hapticsEnabled: Bool { defaults.object(forKey: Key.haptics) as? Bool ?? true }
    static var edgeGlowEnabled: Bool { defaults.object(forKey: Key.edgeGlow) as? Bool ?? true }
    static var scanTextOnOpen: Bool { defaults.object(forKey: Key.scanTextOnOpen) as? Bool ?? true }

    /// Открывать только что сделанный скриншот сразу при запуске приложения.
    public static var autoOpenRecentScreenshot: Bool {
        defaults.object(forKey: Key.autoOpenRecent) as? Bool ?? true
    }

    static var searchEngine: SearchEngine {
        defaults.string(forKey: Key.searchEngine).flatMap(SearchEngine.init(rawValue:)) ?? .googleLens
    }
}

/// Константы, которые задаёт автор приложения (не пользователь).
public enum AppConfig {
    /// iCloud-ссылка на готовую команду «Сделать снимок экрана → Обвести и найти».
    /// Создайте команду один раз, «Поделиться → Скопировать ссылку iCloud» и вставьте сюда —
    /// тогда пользователи будут добавлять её одной кнопкой.
    public static let backTapShortcutURL: URL? = nil
}
