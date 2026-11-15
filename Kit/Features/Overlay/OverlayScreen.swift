import SwiftUI

/// Полноэкранный оверлей «Обвести и найти» поверх замороженного скриншота.
public struct OverlayScreen: View {
    @StateObject private var model: OverlayViewModel
    @State private var glowIntensity: Double = 0
    @State private var chromeVisible = false
    private let onClose: () -> Void

    public init(capture: Capture, onClose: @escaping () -> Void) {
        _model = StateObject(wrappedValue: OverlayViewModel(capture: capture))
        self.onClose = onClose
    }

    public var body: some View {
        canvas
            .overlay(alignment: .top) { topBar }
            .overlay(alignment: .bottom) { bottomBar }
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
            .preferredColorScheme(.dark)
            .onAppear(perform: appear)
            .sheet(isPresented: $model.isResultsPresented, onDismiss: model.clearSelection) {
                ResultsSheet(model: model)
                    .presentationDetents([.fraction(0.45), .large])
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
                    .presentationCornerRadius(28)
                    .presentationDragIndicator(.visible)
            }
    }

    // MARK: - Холст

    private var canvas: some View {
        GeometryReader { geo in
            let frame = LassoGeometry.aspectFitRect(
                for: model.capture.image.size,
                in: CGRect(origin: .zero, size: geo.size)
            )

            ZStack {
                Color.black

                Image(uiImage: model.capture.image)
                    .resizable()
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)

                dimming

                ForEach(model.highlightedText) { line in
                    let r = model.viewRect(for: line.normalizedBox)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.textHighlight)
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                        .transition(.opacity)
                }

                if let selection = model.selection {
                    let rect = model.viewRect(for: selection)
                    if model.isBusy {
                        ScanShimmer()
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                    SelectionEditor(
                        rect: rect,
                        onChange: model.updateSelection(viewRect:),
                        onEnd: model.selectionEditingEnded
                    )
                    .opacity(model.isFrameVisible ? 1 : 0)
                }

                StrokeTrail(points: model.strokePoints)
                    .opacity(model.strokeOpacity)

                if AppSettings.edgeGlowEnabled {
                    EdgeGlow(intensity: model.isBusy ? max(glowIntensity, 0.8) : glowIntensity)
                        .animation(AnimationTokens.glowSettle, value: model.isBusy)
                }
            }
            .contentShape(Rectangle())
            .gesture(drawGesture)
            .onChange(of: geo.size, initial: true) { model.imageFrame = frame }
        }
        .ignoresSafeArea()
    }

    private var dimming: some View {
        let cutout = model.selection.map(model.viewRect(for:)) ?? .zero
        let opacity = model.selection == nil ? Theme.Dim.idle : Theme.Dim.selected
        return DimmingShape(cutout: cutout)
            .fill(Color.black.opacity(opacity), style: FillStyle(eoFill: true))
            .animation(AnimationTokens.dim, value: opacity)
            .allowsHitTesting(false)
    }

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { model.strokeChanged(to: $0.location) }
            .onEnded { _ in model.strokeEnded() }
    }

    // MARK: - Хром

    private var topBar: some View {
        HStack(alignment: .top) {
            CircleIconButton(systemImage: "xmark", action: onClose)
                .accessibilityLabel("Закрыть")
            Spacer()
        }
        .overlay(alignment: .top) {
            if model.phase == .idle && model.selection == nil {
                HintCapsule(text: "Обведите или коснитесь, чтобы найти")
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .opacity(chromeVisible ? 1 : 0)
        .animation(AnimationTokens.chrome, value: model.phase)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if !model.isResultsPresented {
            SearchPill(text: $model.queryText) {
                model.runSearch(refinement: model.queryText)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .opacity(chromeVisible ? 1 : 0)
            .offset(y: chromeVisible ? 0 : 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Появление

    private func appear() {
        model.onAppear()
        withAnimation(AnimationTokens.glowIn) { glowIntensity = 1 }
        withAnimation(AnimationTokens.chrome.delay(0.15)) { chromeVisible = true }
        Task {
            try? await Task.sleep(for: AnimationTokens.glowSettleDelay)
            withAnimation(AnimationTokens.glowSettle) { glowIntensity = 0.35 }
        }
    }
}
