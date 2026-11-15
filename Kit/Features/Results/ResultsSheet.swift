import SwiftUI
import Translation

/// Шторка результатов: превью фрагмента, уточнение запроса, быстрые действия и выдача.
struct ResultsSheet: View {
    @ObservedObject var model: OverlayViewModel
    @State private var refinement = ""
    @State private var showTranslation = false
    @State private var copied = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 12) {
            header
            if !quickActionsEmpty { quickActions }
            if model.isGoogleConfigured {
                Picker("Источник", selection: $model.resultsTab) {
                    Text("Google").tag(OverlayViewModel.ResultsTab.google)
                    Text("Веб").tag(OverlayViewModel.ResultsTab.web)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
            }
            // Обе вкладки живут одновременно, чтобы WebView не перезагружался при переключении.
            let showGoogle = model.isGoogleConfigured && model.resultsTab == .google
            ZStack {
                content
                    .opacity(showGoogle ? 0 : 1)
                    .allowsHitTesting(!showGoogle)
                if model.isGoogleConfigured {
                    GoogleResultsList(
                        results: model.webResults,
                        isLoading: model.isLoadingWebResults,
                        error: model.webResultsError,
                        onOpen: model.openPage,
                        onSearchText: model.searchText
                    )
                    .opacity(showGoogle ? 1 : 0)
                    .allowsHitTesting(showGoogle)
                }
            }
        }
        .padding(.top, 20)
        .translationPresentation(isPresented: $showTranslation, text: model.recognition.fullText)
        .animation(AnimationTokens.chrome, value: model.recognition.texts.count)
    }

    // MARK: Шапка

    private var header: some View {
        HStack(spacing: 12) {
            if let crop = model.croppedImage {
                Image(uiImage: crop)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.thumbnail, style: .continuous))
            }
            TextField("Добавить к поиску", text: $refinement)
                .submitLabel(.search)
                .onSubmit { model.runSearch(refinement: refinement) }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
        .padding(.horizontal, 16)
    }

    // MARK: Быстрые действия

    private var quickActionsEmpty: Bool {
        !model.recognition.hasText && model.recognition.codes.isEmpty
    }

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(model.recognition.codes) { code in
                    if let url = code.url {
                        ActionChip(title: url.host() ?? code.payload, systemImage: "link") { openURL(url) }
                    } else {
                        ActionChip(title: code.payload, systemImage: "qrcode") { UIPasteboard.general.string = code.payload }
                    }
                }
                if model.recognition.hasText {
                    ActionChip(title: copied ? "Скопировано" : "Копировать текст",
                               systemImage: copied ? "checkmark" : "doc.on.doc") {
                        UIPasteboard.general.string = model.recognition.fullText
                        copied = true
                    }
                    ActionChip(title: "Перевести", systemImage: "translate") { showTranslation = true }
                    ActionChip(title: "Искать текст", systemImage: "text.magnifyingglass") {
                        model.searchText(model.recognition.fullText)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: Выдача

    @ViewBuilder
    private var content: some View {
        if let error = model.errorMessage {
            ContentUnavailableView("Не удалось выполнить поиск", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if let request = model.searchRequest {
            ZStack(alignment: .top) {
                SearchWebView(request: request, isLoading: $model.isLoadingResults)
                if model.isLoadingResults {
                    ProgressView().progressViewStyle(.linear).tint(Theme.blue)
                }
            }
        } else {
            ProgressView().frame(maxHeight: .infinity)
        }
    }
}
