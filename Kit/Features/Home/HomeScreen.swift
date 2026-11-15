import AppIntents
import PhotosUI
import SwiftUI

/// Главный экран: инструкция по настройке быстрого запуска + ручной запуск.
public struct HomeScreen: View {
    private let onImage: (UIImage, CaptureSource) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var isLoadingLatest = false

    public init(onImage: @escaping (UIImage, CaptureSource) -> Void) {
        self.onImage = onImage
    }

    public var body: some View {
        NavigationStack {
            List {
                Section { hero }
                    .listRowBackground(Color.clear)

                Section {
                    SetupStep(number: 1, text: "Укажите API-ключ Google в настройках (значок ⚙︎).")
                    SetupStep(number: 2, text: "Сделайте скриншот (боковая кнопка + громкость вверх) — откроется системный поиск по экрану.")
                    SetupStep(number: 3, text: "Обведите объект пальцем и выберите «Обвести и найти» в результатах.")
                } header: {
                    Text("Не выходя из приложения · iOS 26")
                } footer: {
                    Text("Всё происходит в системном интерфейсе поверх текущего приложения — оно не уходит в фон. Нужен iPhone с Apple Intelligence.")
                }

                Section {
                    SetupStep(number: 1, text: "Откройте «Команды» и создайте команду: «Сделать снимок экрана» → «Обвести и найти».")
                    SetupStep(number: 2, text: "Назначьте её на Action Button или Back Tap (Универсальный доступ → Касание → Касание задней панели).")
                    ShortcutsLink()
                        .shortcutsLinkStyle(.automaticOutline)
                        .frame(maxWidth: .infinity)
                } header: {
                    Text("Полный оверлей")
                } footer: {
                    Text("Наш оверлей со свечением и рамкой. Открывает приложение, поэтому текущее приложение уходит в фон.")
                }

                Section("Попробовать сейчас") {
                    Button {
                        Task { await openLatestScreenshot() }
                    } label: {
                        Label("Последний скриншот", systemImage: "camera.viewfinder")
                    }
                    .disabled(isLoadingLatest)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Выбрать изображение", systemImage: "photo.on.rectangle")
                    }
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Обвести и найти")
            .toolbar {
                NavigationLink { SettingsScreen() } label: { Image(systemName: "gearshape") }
            }
            .onChange(of: pickerItem) {
                guard let item = pickerItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        onImage(image, .photoLibrary)
                    }
                    pickerItem = nil
                }
            }
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Circle()
                .strokeBorder(AngularGradient(colors: Theme.glowColors, center: .center), lineWidth: 6)
                .frame(width: 84, height: 84)
                .overlay(Image(systemName: "magnifyingglass").font(.largeTitle.weight(.semibold)))
            Text("Обведите что угодно на экране — и найдите это.")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func openLatestScreenshot() async {
        isLoadingLatest = true
        defer { isLoadingLatest = false }
        do {
            let image = try await LatestScreenshotProvider().fetch()
            errorMessage = nil
            onImage(image, .photoLibrary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SetupStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.footnote.bold())
                .frame(width: 22, height: 22)
                .background(Theme.blue.opacity(0.15), in: Circle())
                .foregroundStyle(Theme.blue)
            Text(text).font(.subheadline)
        }
    }
}
