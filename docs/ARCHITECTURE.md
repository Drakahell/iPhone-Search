# Архитектура

## Структура

```
.
├── project.yml                  XcodeGen-описание всех таргетов (единственный источник правды)
├── App/                         Таргет приложения — тонкий слой «склейки»
│   ├── CircleSearchApp.swift    @main, scenePhase, deep links
│   ├── Routing/                 RootView (Home + fullScreenCover оверлея), DeepLink
│   ├── Intents/                 App Intents и AppShortcuts (запуск из «Команд», Siri, Action Button)
│   └── VisualIntelligence/      Поставщик результатов для системного Visual Intelligence (iOS 26):
│                                IntentValueQuery, WebResultEntity, OpenIntent — работает в фоне
│
├── Kit/                         Фреймворк CircleSearchKit — вся логика, UI и анимации
│   ├── Core/                    Логика без отрисовки (UI-фреймворки только для типов)
│   │   ├── Models/              Capture, RecognitionResult, SearchQuery
│   │   ├── Capture/             CaptureRouter (показ оверлея), LatestScreenshotProvider
│   │   ├── Geometry/            Классификация жеста, нормализация координат, сглаживание, уголки
│   │   ├── Imaging/             Кадрирование, ориентация, подготовка JPEG
│   │   ├── Recognition/         Vision: OCR, штрихкоды, поиск объекта под пальцем
│   │   ├── Search/              SearchProvider + реализации (Google Lens), multipart
│   │   │   └── Google/          GoogleVisionClient (Cloud Vision Web Detection), модели выдачи
│   │   └── Settings/            AppSettings (UserDefaults App Group)
│   ├── Features/                Экраны: View + ViewModel на каждую фичу
│   │   ├── Overlay/             OverlayScreen, OverlayViewModel, SelectionEditor
│   │   ├── Results/             ResultsSheet, SearchWebView
│   │   ├── Home/                Онбординг и ручной запуск
│   │   └── Settings/            Экран настроек
│   ├── UI/                      Переиспользуемый интерфейс
│   │   ├── DesignSystem/        Theme: цвета, радиусы, толщины, уровни затемнения
│   │   └── Components/          SearchPill, ActionChip, CircleIconButton, HintCapsule
│   ├── Animations/              Всё, что двигается и ощущается
│   │   ├── AnimationTokens      Пружины, длительности, периоды
│   │   ├── EdgeGlow             Переливающееся свечение по краям экрана
│   │   ├── StrokeTrail          Светящийся след пальца
│   │   ├── SelectionShapes      Анимируемые CornerBrackets и DimmingShape (морфинг рамки)
│   │   ├── ScanShimmer          Блик сканирования во время поиска
│   │   └── Haptics              Тактильные события
│   └── Shared/                  Код для обмена с расширениями (App Group)
│
├── Extensions/ShareExtension/   Share Extension — показывает OverlayScreen внутри себя
├── Resources/                   Assets.xcassets
├── Tests/CircleSearchKitTests/  Юнит-тесты Core
└── docs/                        Документация
```

## Зависимости между слоями

```
App ─┐
     ├──► Kit/Features ──► Kit/UI ──► Kit/Animations
Ext ─┘          │                         │
                └──────► Kit/Core ◄───────┘
                              │
                              ▼
                         Kit/Shared
```

Правила:
- **Core** не импортирует ничего из Features/UI/Animations. Здесь живёт тестируемая логика.
- **Features** не знают, откуда пришёл снимок: получают `Capture` и колбэк закрытия.
- **Animations** не содержат бизнес-логики: принимают значения (`intensity`, `rect`, `points`) и рисуют.
- **App** и **Extensions** только склеивают: собирают `Capture` и показывают `OverlayScreen`.
- Фреймворк собирается с `APPLICATION_EXTENSION_API_ONLY`: никакого `UIApplication.shared` внутри Kit.

## Поток данных в оверлее

```
DragGesture ──► OverlayViewModel.strokeChanged / strokeEnded
                    │
                    ├─ LassoGeometry.classify ──► .region(rect) ──► commit(normalized:)
                    │                         └─► .tap(point)  ──► строка OCR | SubjectLocator | фолбэк
                    ▼
               commit: морфинг рамки (AnimationTokens.selectionMorph) + хаптика
                    ▼
               runSearch: ImageCropper ──► SearchCoordinator ──► URLRequest ──► SearchWebView
                                       └─► VisionAnalyzer (текст, QR) ──► быстрые действия
```

Координаты выделения хранятся **нормализованными (0…1)** относительно изображения — это делает их
независимыми от размера экрана, поворота и масштаба отрисовки.

## Поток Visual Intelligence (без ухода из текущего приложения)

```
Скриншот / Action Button ──► системный UI Visual Intelligence поверх приложения
        │  пользователь обводит область
        ▼
iOS будит наш процесс в фоне ──► GoogleVisualSearchQuery.values(for: SemanticContentDescriptor)
        │                              ├─ pixelBuffer ──► GoogleVisionClient.webDetection
        │                              └─ labels (фолбэк без ключа) ──► GoogleWebSearch
        ▼
[WebResultEntity] ──► системная выдача; тап по результату ──► OpenWebResultIntent (открывает наше приложение)
```

## Как вносить изменения

| Задача | Где менять |
|---|---|
| Новый поисковик (Яндекс, Bing…) | новый `SearchProvider` в `Core/Search` + case в `SearchEngine` |
| Другие цвета, радиусы | `UI/DesignSystem/Theme.swift` |
| Скорость/упругость анимаций | `Animations/AnimationTokens.swift` |
| Новый эффект | файл в `Animations/`, подключение в `OverlayScreen` |
| Новое быстрое действие | `Features/Results/ResultsSheet.swift` (`quickActions`) |
| Новая точка запуска | `App/Intents` или новое расширение в `Extensions/` + таргет в `project.yml` |
| Новая настройка | ключ в `Core/Settings/AppSettings.swift` + переключатель в `SettingsScreen` |

## Известные ограничения

- Нет системного оверлея поверх живого экрана (ограничение iOS) — работаем со снимком.
- У Google Lens нет публичного API — используется веб-загрузка. Изоляция в `GoogleLensProvider`
  позволяет заменить её одной правкой.
- Share Extension ограничен по памяти (~120 МБ) — снимки при загрузке уменьшаются до 1600 px.

## Дорожная карта

- [ ] Локальный «Visual Look Up» через VisionKit `ImageAnalyzer` как офлайн-движок
- [ ] Выделение по точной маске объекта (не только bounding box), анимация «вырезания»
- [ ] Выделение отдельных слов, а не строк (`VNRecognizedText.boundingBox(for:)`)
- [ ] История поисков
- [ ] Виджет Control Center (iOS 18 `ControlWidget`) для запуска
- [ ] UI-тесты оверлея и snapshot-тесты анимаций
