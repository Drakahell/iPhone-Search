import SwiftUI

/// Быстрое действие под результатами: «Копировать», «Перевести», «Открыть ссылку».
struct ActionChip: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}

/// Лёгкое «вдавливание» при нажатии.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(AnimationTokens.press, value: configuration.isPressed)
    }
}
