import SwiftUI

/// Нижняя строка поиска — как в Circle to Search.
struct SearchPill: View {
    @Binding var text: String
    var placeholder = "Поиск"
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.strokeGradient)

            TextField(placeholder, text: $text)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15)))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .animation(AnimationTokens.chrome, value: text.isEmpty)
    }
}
