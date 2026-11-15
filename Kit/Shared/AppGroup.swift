import Foundation

/// Общий контейнер App Group — мост между приложением и расширениями.
public enum AppGroup {
    public static let identifier = "group.com.example.circlesearch"

    public static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.temporaryDirectory
    }

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
