import AppIntents

/// Команды, доступные сразу после установки (Siri, Spotlight, Action Button).
struct CircleSearchShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchLatestScreenshotIntent(),
            phrases: [
                "Обвести и найти в \(.applicationName)",
                "Найти на экране в \(.applicationName)",
            ],
            shortTitle: "Последний скриншот",
            systemImageName: "circle.dashed"
        )
    }

    static var shortcutTileColor: ShortcutTileColor = .blue
}
