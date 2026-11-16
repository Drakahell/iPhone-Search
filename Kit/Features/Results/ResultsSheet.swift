import SwiftUI

/// Шторка результатов: только выдача Google, без лишних элементов.
struct ResultsSheet: View {
    @ObservedObject var model: OverlayViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Переключатель появляется, только если задан ключ Google Cloud Vision.
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
                webContent
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
        .padding(.top, 14)   // место под «ручку» шторки
    }

    @ViewBuilder
    private var webContent: some View {
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
