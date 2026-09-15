import SwiftUI

struct AboutView: View {
    @State private var showingAcknowledgments = false

    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().scaledToFit().frame(width: 40, height: 40)
            Text("Rations").font(.headline)
            Text(version).font(.caption).foregroundStyle(.secondary)
            Text("If you have to ask when it resets, you’re already in line.")
                .multilineTextAlignment(.center)
            if let github = URL(string: "https://github.com/rawcontext/rations") {
                Link("GitHub", destination: github)
            }
            if let context = URL(string: "https://rawcontext.com") { Link("© Context", destination: context) }
            Button("Acknowledgments…") { showingAcknowledgments = true }
                .controlSize(.small)
        }
        .padding(28).frame(width: 320)
        .sheet(isPresented: $showingAcknowledgments) { AcknowledgmentsView() }
    }

    private var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        return "Version \(version) (\(build))"
    }
}
