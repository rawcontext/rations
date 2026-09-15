import SwiftUI

struct AcknowledgmentsView: View {
    @Environment(\.dismiss) private var dismiss
    private let notices = [("Sparkle", "SparkleLicense"),
                           ("Cursor adapter — CodexBar", "CodexBarAttribution"),
                           ("Menu icon — CdnMCG", "IconAttribution"),
                           ("Rations", "RationsLicense")]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Acknowledgments").font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(notices.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(notices[index].0).fontWeight(.semibold)
                            Text(license(notices[index].1)).font(.system(size: 11)).textSelection(.enabled)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
            }
        }
        .padding(20).frame(width: 500, height: 400)
    }

    private func license(_ name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "Notice unavailable." }
        return text
    }
}
