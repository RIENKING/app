import Foundation
import UIKit

@MainActor
final class HapticService {
    static let shared = HapticService()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private init() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
    }

    func impact(_ intensity: HapticIntensity, enabled: Bool) {
        guard enabled, intensity != .none else { return }
        switch intensity {
        case .none:
            break
        case .light:
            lightGenerator.impactOccurred()
        case .medium:
            mediumGenerator.impactOccurred()
        case .heavy:
            heavyGenerator.impactOccurred()
        }
    }

    func selection(enabled: Bool) {
        guard enabled else { return }
        selectionGenerator.selectionChanged()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType, enabled: Bool) {
        guard enabled else { return }
        notificationGenerator.notificationOccurred(type)
    }
}
