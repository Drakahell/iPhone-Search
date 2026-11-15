import SwiftUI

/// Нативная выдача Google (Cloud Vision Web Detection): догадка, сущности,
/// похожие изображения и страницы с совпадениями.
struct GoogleResultsList: View {
    let results: WebSearchResults?
    let isLoading: Bool
    let error: String?
    let onOpen: (WebPage) -> Void
    let onSearchText: (String) -> Void

    var body: some View {
        if let error {
            ContentUnavailableView("Google недоступен", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if let results, !results.isEmpty {
            list(results)
        } else if isLoading {
            ProgressView("Ищем в Google…").frame(maxHeight: .infinity)
        } else {
            ContentUnavailableView("Ничего не найдено", systemImage: "magnifyingglass",
                                   description: Text("Попробуйте выделить объект точнее."))
        }
    }

    private func list(_ results: WebSearchResults) -> some View {
        List {
            if let guess = results.bestGuess {
                Section {
                    Button { onSearchText(guess) } label: {
                        Label(guess.capitalized, systemImage: "sparkle.magnifyingglass")
                            .font(.headline)
                    }
                }
            }

            if !results.entities.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(results.entities, id: \.self) { entity in
                                ActionChip(title: entity, systemImage: "tag") { onSearchText(entity) }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            }

            if !results.similarImages.isEmpty {
                Section("Похожие изображения") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(results.similarImages, id: \.self) { url in
                                RemoteThumbnail(url: url, size: 96)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
            }

            if !results.pages.isEmpty {
                Section("Страницы") {
                    ForEach(results.pages) { page in
                        Button { onOpen(page) } label: { WebPageRow(page: page) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct WebPageRow: View {
    let page: WebPage

    var body: some View {
        HStack(spacing: 12) {
            RemoteThumbnail(url: page.imageURL, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(page.title).font(.subheadline.weight(.semibold)).lineLimit(2)
                Text(page.url.host() ?? page.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

private struct RemoteThumbnail: View {
    let url: URL?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Color(.tertiarySystemFill)
                    .overlay(Image(systemName: "photo").foregroundStyle(.tertiary))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.thumbnail, style: .continuous))
    }
}
