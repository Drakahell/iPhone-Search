import Foundation
import Security

/// API-ключ Google Cloud в Keychain с общей группой доступа (App Group),
/// чтобы его видели приложение, Share Extension и фоновые App Intents.
public enum GoogleAPIKeyStore {
    private static let service = "com.example.circlesearch.google"
    private static let account = "cloud-vision-api-key"

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: AppGroup.identifier,
        ]
    }

    public static var isConfigured: Bool { load()?.isEmpty == false }

    public static func load() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Пустая строка удаляет ключ.
    @discardableResult
    public static func save(_ key: String) -> Bool {
        delete()
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        var query = baseQuery
        query[kSecValueData as String] = Data(trimmed.utf8)
        // Доступен после первой разблокировки — нужно для фоновых запросов Visual Intelligence.
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    public static func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
