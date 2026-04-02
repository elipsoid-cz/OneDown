import SwiftUI
import FinderSync

struct ContentView: View {
    @State private var isExtensionEnabled = false
    @State private var showUninstallConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 6) {
                Text("OneDown")
                    .font(.title.bold())
                Text("Permanently delete files from Finder toolbar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 28)
            .padding(.bottom, 24)

            // Status
            VStack(spacing: 16) {
                if isExtensionEnabled {
                    Label("The Delete Forever button is ready in your Finder toolbar.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.body)

                    Text("You can close this app — the button works without it.\nThe first click will ask for permission to control Finder.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Link(destination: URL(string: "https://buymeacoffee.com/elipsoid")!) {
                        HStack(spacing: 6) {
                            Text("🍎")
                            Text("Help fund my dev account")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(red: 1.0, green: 0.867, blue: 0.0))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Label("Extension could not be activated.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.body)

                    Text("This can happen on some macOS configurations.\nPlease open an issue on GitHub so we can help.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Link(destination: URL(string: "https://github.com/elipsoid-cz/OneDown/issues")!) {
                        Label("Report Issue on GitHub", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider()
                .padding(.horizontal, 40)

            Button("Uninstall OneDown\u{2026}") {
                showUninstallConfirmation = true
            }
            .buttonStyle(.plain)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.vertical, 12)
        }
        .frame(width: 520)
        .alert("Uninstall OneDown?", isPresented: $showUninstallConfirmation) {
            Button("Uninstall", role: .destructive) { performUninstall() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The AppleScript file will be deleted and OneDown will be moved to the Trash. You can also disable the extension in System Settings → Privacy & Security → Extensions → Finder Extensions.")
        }
        .onAppear { refreshStatus() }
        // Re-check when the app comes back to the foreground (user may have
        // just toggled the extension in System Settings).
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in refreshStatus() }
    }

    // MARK: - Helpers

    private func refreshStatus() {
        isExtensionEnabled = FIFinderSyncController.isExtensionEnabled
    }

    private func performUninstall() {
        // 1. Delete AppleScript file
        let scriptURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Scripts/io.github.onedown-app.OneDown.Extension/DeletePermanently.applescript")
        try? FileManager.default.removeItem(at: scriptURL)

        // 2. Restart Finder so the toolbar button disappears immediately
        let killFinder = Process()
        killFinder.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        killFinder.arguments = ["Finder"]
        try? killFinder.run()

        // 3. Move the app bundle to Trash (only when running from /Applications)
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.path.hasPrefix("/Applications/") else {
            NSApplication.shared.terminate(nil)
            return
        }
        NSWorkspace.shared.recycle([bundleURL]) { _, _ in
            NSApplication.shared.terminate(nil)
        }
    }

}

#Preview {
    ContentView()
}
