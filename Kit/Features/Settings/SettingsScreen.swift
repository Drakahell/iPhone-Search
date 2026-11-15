import SwiftUI

public struct SettingsScreen: View {
    @AppStorage(AppSettings.Key.haptics, store: AppGroup.defaults) private var haptics = true
    @AppStorage(AppSettings.Key.edgeGlow, store: AppGroup.defaults) private var edgeGlow = true
    @AppStorage(AppSettings.Key.scanTextOnOpen, store: AppGroup.defaults) private var scanText = true
    @AppStorage(AppSettings.Key.searchEngine, store: AppGroup.defaults) private var engine = SearchEngine.googleLens.rawValue

    @State private var apiKey = ""
    @State private var keySaved = GoogleAPIKeyStore.isConfigured

    public init() {}

    public var body: some View {
        Form {
            Section {
                SecureField("API-ключ Google Cloud", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(saveKey)
                Button(keySaved ? "Обновить ключ" : "Сохранить ключ", action: saveKey)
                    .disabled(apiKey.isEmpty)
                if keySaved {
                    Label("Ключ сохранён в Keychain", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(Theme.green)
                    Button("Удалить ключ", role: .destructive) {
                        GoogleAPIKeyStore.delete()
                        keySaved = false
                    }
                }
                Link("Включить Cloud Vision API",
                     destination: URL(string: "https://console.cloud.google.com/apis/library/vision.googleapis.com")!)
            } header: {
                Text("Google поиск по изображению")
            } footer: {
                Text("Нужен для нативной выдачи Google в оверлее и для поиска в системном Visual Intelligence. Без ключа работает веб-выдача Google Lens.")
            }

            Section("Веб-поиск") {
                Picker("Поисковик", selection: $engine) {
                    ForEach(SearchEngine.allCases) { Text($0.title).tag($0.rawValue) }
                }
                Toggle("Распознавать текст при открытии", isOn: $scanText)
            }

            Section("Ощущения") {
                Toggle("Свечение по краям", isOn: $edgeGlow)
                Toggle("Тактильный отклик", isOn: $haptics)
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
