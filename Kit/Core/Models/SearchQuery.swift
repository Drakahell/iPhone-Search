import UIKit

/// Что именно ищем: вырезанный фрагмент, текст или их комбинацию (мультипоиск).
enum SearchQuery {
    case image(UIImage)
    case text(String)
    case imageAndText(UIImage, String)
}
