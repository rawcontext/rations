import SwiftUI

struct SettingsTabControl: View {
    let tab: SettingsTab
    let store: RationsStore
    @Environment(\.colorScheme) private var colorScheme

    private var selected: Bool { store.selectedTab == tab }

    var body: some View {
        Button { store.selectedTab = tab } label: {
            VStack(spacing: 5) {
                Image(systemName: tab.symbol).font(.system(size: 20, weight: .regular))
                Text(tab.title).font(.system(size: 12, weight: selected ? .semibold : .regular))
            }
            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            .frame(width: 78, height: 58)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(.black.opacity(colorScheme == .dark ? 0.18 : 0.06))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
