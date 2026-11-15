import SwiftUI

/// Состояние и логика оверлея. Ничего не знает о том, как это нарисовано.
@MainActor
final class OverlayViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle        // ждём жест, показана подсказка
        case drawing     // пользователь ведёт пальцем
        case locating    // тап: ищем объект под пальцем
        case selected    // есть выделение
    }

    let capture: Capture

    // MARK: Состояние для UI
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var strokePoints: [CGPoint] = []
    @Published private(set) var strokeOpacity: Double = 1
    /// Выделение в нормализованных координатах изображения.
    @Published private(set) var selection: CGRect?
    @Published private(set) var isFrameVisible = false
    @Published private(set) var highlightedText: [RecognizedText] = []
    @Published private(set) var croppedImage: UIImage?
    @Published private(set) var recognition: RecognitionResult = .empty
    @Published private(set) var searchRequest: URLRequest?
    @Published var isResultsPresented = false
    @Published var isLoadingResults = false
    @Published var queryText = ""
    @Published var errorMessage: String?

    // MARK: Нативные результаты Google (Cloud Vision)
    enum ResultsTab: Hashable { case google, web }
    @Published var resultsTab: ResultsTab = .web
    @Published private(set) var webResults: WebSearchResults?
    @Published private(set) var isLoadingWebResults = false
    @Published private(set) var webResultsError: String?
    let isGoogleConfigured = GoogleAPIKeyStore.isConfigured

    var isBusy: Bool {
        phase == .locating || (resultsTab == .google ? isLoadingWebResults : isLoadingResults)
    }

    /// Где изображение нарисовано во вью — задаётся экраном при раскладке.
    var imageFrame: CGRect = .zero

    // MARK: Зависимости
    private let analyzer: ImageAnalyzing
    private let subjectLocator: SubjectLocator
    private let searchCoordinator: SearchCoordinator

    private var screenText: [RecognizedText] = []
    private var searchTask: Task<Void, Never>?
    private var webSearchTask: Task<Void, Never>?

    init(
        capture: Capture,
        analyzer: ImageAnalyzing = VisionAnalyzer(),
        subjectLocator: SubjectLocator = SubjectLocator(),
        search: SearchCoordinator = SearchCoordinator()
    ) {
        self.capture = capture
        self.analyzer = analyzer
        self.subjectLocator = subjectLocator
        self.searchCoordinator = search
    }

    // MARK: - Жизненный цикл

    func onAppear() {
        Haptics.shared.overlayOpened()
        guard AppSettings.scanTextOnOpen else { return }
        // Заранее распознаём текст на всём экране — для тапа по строке и подсветки.
        Task { [weak self, analyzer, image = capture.image] in
            let result = try? await analyzer.analyze(image, features: .text)
            self?.screenText = result?.texts ?? []
        }
    }

    // MARK: - Рисование

    func strokeChanged(to point: CGPoint) {
        if phase != .drawing {
            phase = .drawing
            strokePoints = []
            strokeOpacity = 1
            withAnimation(AnimationTokens.dim) {
                selection = nil
                isFrameVisible = false
                highlightedText = []
            }
            Haptics.shared.strokeBegan()
        }
        strokePoints.append(point)
    }

    func strokeEnded() {
        guard let kind = LassoGeometry.classify(strokePoints) else { return reset() }
        switch kind {
        case .tap(let point):
            strokePoints = []
            handleTap(at: point)
        case .region(let rect):
            commit(normalized: LassoGeometry.normalize(rect.insetBy(dx: -10, dy: -10), in: imageFrame))
            withAnimation(AnimationTokens.strokeFade) { strokeOpacity = 0 }
        }
    }

    private func handleTap(at point: CGPoint) {
        let n = LassoGeometry.normalize(point, in: imageFrame)

        // 1. Тап по строке текста
        if let line = screenText.first(where: { $0.normalizedBox.insetBy(dx: -0.01, dy: -0.006).contains(n) }) {
            commit(normalized: line.normalizedBox.insetBy(dx: -0.012, dy: -0.008))
            return
        }

        // 2. Тап по объекту
        phase = .locating
        Task { [weak self, subjectLocator, image = capture.image] in
            let rect = await subjectLocator.subjectRect(in: image, at: n)
            guard let self else { return }
            // 3. Фолбэк — область вокруг точки
            let fallback = CGRect(x: n.x - 0.15, y: n.y - 0.08, width: 0.3, height: 0.16)
            self.commit(normalized: (rect ?? fallback).insetBy(dx: -0.01, dy: -0.01))
        }
    }

    // MARK: - Выделение

    func viewRect(for normalized: CGRect) -> CGRect {
        LassoGeometry.denormalize(normalized, in: imageFrame)
    }

    /// Фиксирует выделение с морфинг-анимацией и запускает поиск.
    func commit(normalized rect: CGRect) {
        let target = rect.clampedToUnit()

        if selection == nil {
            // Стартуем рамку чуть шире — затем она «сжимается» к объекту.
            selection = target.insetBy(dx: -target.width * 0.08, dy: -target.height * 0.08)
        }
        DispatchQueue.main.async { [self] in
            withAnimation(AnimationTokens.selectionMorph) {
                selection = target
                isFrameVisible = true
                phase = .selected
                highlightedText = screenText.filter { target.intersects($0.normalizedBox) }
            }
        }
        Haptics.shared.selectionConfirmed()
        runSearch()
    }

    /// Ресайз за уголки (в координатах вью), без анимации и без поиска.
    func updateSelection(viewRect: CGRect) {
        selection = LassoGeometry.normalize(viewRect, in: imageFrame).clampedToUnit()
        highlightedText = screenText.filter { selection?.intersects($0.normalizedBox) == true }
    }

    func selectionEditingEnded() {
        guard let selection else { return }
        commit(normalized: selection)
    }

    func clearSelection() {
        searchTask?.cancel()
        webSearchTask?.cancel()
        isLoadingWebResults = false
        withAnimation(AnimationTokens.selectionMorph) { reset() }
    }

    private func reset() {
        phase = .idle
        strokePoints = []
        selection = nil
        isFrameVisible = false
        highlightedText = []
        isLoadingResults = false
    }

    // MARK: - Поиск

    /// Поиск по выделению (и уточняющему тексту, если есть) либо чисто текстовый.
    func runSearch(refinement: String? = nil) {
        searchTask?.cancel()
        let refinement = refinement?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let selection else {
            if let refinement, !refinement.isEmpty { search(.text(refinement), crop: nil) }
            return
        }
        guard let crop = ImageCropper.crop(capture.image, normalizedRect: selection) else { return }

        if let refinement, !refinement.isEmpty {
            search(.imageAndText(crop, refinement), crop: crop)
        } else {
            search(.image(crop), crop: crop)
        }
    }

    /// Текстовый поиск (по распознанному тексту или сущности) — во вкладке «Веб», выделение не трогаем.
    func searchText(_ text: String) {
        guard let request = try? searchCoordinator.request(for: .text(text)) else { return }
        openInWeb(request)
    }

    /// Открыть страницу из нативных результатов Google прямо в шторке.
    func openPage(_ page: WebPage) {
        openInWeb(URLRequest(url: page.url))
    }

    private func openInWeb(_ request: URLRequest) {
        searchRequest = request
        errorMessage = nil
        isLoadingResults = true
        resultsTab = .web
        isResultsPresented = true
    }

    private func search(_ query: SearchQuery, crop: UIImage?) {
        croppedImage = crop
        do {
            searchRequest = try searchCoordinator.request(for: query)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingResults = true

        startGoogleImageSearch(crop)
        resultsTab = (crop != nil && isGoogleConfigured) ? .google : .web
        isResultsPresented = true

        // Параллельно — локальное распознавание фрагмента для быстрых действий.
        guard let crop else { return }
        searchTask = Task { [weak self, analyzer] in
            let result = (try? await analyzer.analyze(crop, features: .all)) ?? .empty
            guard !Task.isCancelled else { return }
            self?.recognition = result
        }
    }

    /// Обратный поиск через Google Cloud Vision — если ключ задан в настройках.
    private func startGoogleImageSearch(_ crop: UIImage?) {
        webSearchTask?.cancel()
        webResults = nil
        webResultsError = nil
        guard let crop, let client = GoogleVisionClient.configured() else {
            isLoadingWebResults = false
            return
        }
        isLoadingWebResults = true
        webSearchTask = Task { [weak self] in
            do {
                let results = try await client.webDetection(image: crop)
                guard !Task.isCancelled else { return }
                self?.webResults = results
            } catch {
                guard !Task.isCancelled else { return }
                self?.webResultsError = error.localizedDescription
            }
            self?.isLoadingWebResults = false
        }
    }
}
