import Photos
import PhotosUI
import SwiftUI

/// Главный экран: одна понятная инструкция и ручной запуск.
public struct HomeScreen: View {
    private let onImage: (UIImage, CaptureSource) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var isLoadingLatest = false
    @State private var photosAllowed = LatestScreenshotProvider.isAuthorized
    @Environment(\.openURL) private var openURL

    public init(onImage: @escaping (UIImage, CaptureSource) -> Void) {
        self.onImage = onImage
    }

    public var body: some View {
        NavigationStack {
            List {
                Section { hero }
                    .listRowBackground(Color.clear)

                if !photosAllowed {
                    Section {
                        Button {
                            Task { await requestPhotos() }
                        } label: {
                            Label("Разрешить доступ к скриншотам", systemImage: "photo.badge.checkmark")
                                .font(.headline)
                        }
                    } footer: {
                        Text("Нужно один раз — чтобы приложение само открывало только что сделанный скриншот.")
                    }
                }

                Section("Как пользоваться") {
                    UsageRow(symbol: "camera.viewfinder", title: "Сделайте скриншот",
                             text: "Боковая кнопка + громкость вверх.")
                    UsageRow(symbol: "hand.tap", title: "Откройте «Обвести и найти»",
                             text: "Скриншот откроется сам — обведите то, что ищете.")
                    UsageRow(symbol: "square.and.arrow.up", title: "Или через «Поделиться»",
                             text: "Миниатюра скриншота → «Поделиться» → «Обвести и найти». Так вы не уходите из своего приложения.")
                }

                Section {
                    DisclosureGroup("Запуск двойным касанием задней панели") {
                        if let url = AppConfig.backTapShortcutURL {
                            Button("Добавить готовую команду") { openURL(url) }
                        } else {
                            SetupStep(number: 1, text: "«Команды» → + → «Сделать снимок экрана» → «Обвести и найти».")
                        }
                        SetupStep(number: 2, text: "Настройки → Универсальный доступ → Касание → Касание задней панели → Двойное касание → выберите команду.")
                        Button("Открыть «Команды»") { openURL(URL(string: "shortcuts://")!) }
                    }
                }

                Section("Попробовать") {
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
            Text("Обведите что угодно на экране — и найдите это в Google.")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func requestPhotos() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photosAllowed = status == .authorized || status == .limited
    }

    private func openLatestScreenshot() async {
        isLoadingLatest = true
        defer { isLoadingLatest = false }
        do {
            let image = try await LatestScreenshotProvider().fetch()
            errorMessage = nil
            photosAllowed = true
            onImage(image, .photoLibrary)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct UsageRow: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.strokeGradient)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(text).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
