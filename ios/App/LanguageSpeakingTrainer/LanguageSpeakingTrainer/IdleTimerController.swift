import Foundation
import UIKit

/// Lightweight wrapper around the iOS idle timer so it can be controlled from app logic
/// and unit-tested without touching `UIApplication.shared`.
protocol IdleTimerControlling {
    var isIdleTimerDisabled: Bool { get set }
}

@MainActor
struct SystemIdleTimerController: IdleTimerControlling {
    var isIdleTimerDisabled: Bool {
        get { UIApplication.shared.isIdleTimerDisabled }
        set { UIApplication.shared.isIdleTimerDisabled = newValue }
    }
}

