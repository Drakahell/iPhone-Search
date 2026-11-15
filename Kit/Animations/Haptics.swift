import UIKit

/// Тактильный отклик — часть «анимации» ощущений. Все события в одном месте.
@MainActor
final class Haptics {
    static let shared = Haptics()

    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()

    private var enabled: Bool { AppSettings.hapticsEnabled }

    func overlayOpened() {
        guard enabled else { return }
        soft.impactOccurred(intensity: 0.8)
        light.prepare()
    }

    func strokeBegan() {
        guard enabled else { return }
        light.impactOccurred(intensity: 0.5)
        rigid.prepare()
    }

    func selectionConfirmed() {
        guard enabled else { return }
        rigid.impactOccurred(intensity: 0.9)
    }

    func handleGrabbed() {
        guard enabled else { return }
        selection.selectionChanged()
    }
}
