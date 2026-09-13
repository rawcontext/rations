enum SettingsTab: String, CaseIterable {
    case general
    case accounts
    case providers

    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .accounts: "person.fill"
        case .providers: "square.grid.2x2"
        }
    }
}
