import SwiftUI

public struct SettingsScreen: View {
    @AppStorage(AppSettings.Key.haptics, store: AppGroup.defaults) private var haptics = true
    @AppStorage(AppSettings.Key.edgeGlow, store: AppGroup.defaults) private var edgeGlow = true
    @AppStorage(AppSettings.Key.scanTextOnOpen, store: AppGroup.defaults) private var scanText = true
    @AppStorage(AppSettings.Key.autoOpenRecent, store: AppGroup.defaults) private var autoOpen = true

    @State private var apiKey = ""
    @State private var keySaved = GoogleAPIKeyStore.isConfigured

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle("Сразу открывать свежий скриншот", isOn: $autoOpen)
                Toggle("Распознавать текст на экране", isOn: $scanText)
            } header: {
                Text("Основное")
            } footer: {
                Text("Если скриншот сделан меньше минуты назад, он откроется для поиска при запуске приложения.")
            }

            Section("Ощущения") {
                Toggle("Свечение по краям", isOn: $edgeGlow)
                Toggle("Тактильный отклик", isOn: $haptics)
            }

            // Для обычного использования не нужно — поиск Google работает и без ключа.
            Section {
                DisclosureGroup("API-ключ Google Cloud") {
                    SecureField("Вставьте ключ", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit(saveKey)
                    Button(keySaved ? "Обновить ключ" : "Сохранить ключ", action: saveKey)
                        .disabled(apiKey.isEmpty)
                    if keySaved {
                        Label("Ключ сохранён", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.green)
                        Button("Удалить ключ", role: .destructive) {
                            GoogleAPIKeyStore.delete()
                            keySaved = false
                        }
                    }
                }
            } header: {
                Text("Для продвинутых")
            } footer: {
                Text("Необязательно. Добавляет вкладку с результатами Google списком.")
            }
        }
        .navigationTitle("Настройки")
    }

    private func saveKey() {
        guard !apiKey.isEmpty else { return }
        keySaved = GoogleAPIKeyStore.save(apiKey)
        apiKey = ""
    }
}
