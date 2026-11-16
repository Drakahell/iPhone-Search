import Foundation

/// Общий контейнер App Group — мост между приложением и расширениями.
/// Идентификатор берётся из Info.plist (`AppGroupID`), который заполняется из project.yml,
/// поэтому при смене bundle ID ничего в коде менять не нужно.
public enum AppGroup {
    public static let identifier: String =
        Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String
        ?? "group.com.example.circlesearch"

    public static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
            ?? FileManager.default.temporaryDirectory
    }

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
