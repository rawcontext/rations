import RationsCore
import SwiftUI

extension UsageTone {
    var color: Color {
        switch self {
        case .comfortable: .accentColor
        case .warning: .orange
        case .critical: .red
        case .unknown, .stale: .secondary
        }
    }
}
