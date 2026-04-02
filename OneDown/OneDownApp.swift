import SwiftUI

@main
struct OneDownApp: App {

    init() {
        Self.installExtensionScript()
        Self.enableExtensionViaPluginKit()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 340)
    }

    private static func installExtensionScript() {
        let scriptDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Scripts/io.github.onedown-app.OneDown.Extension")
        let scriptURL = scriptDir.appendingPathComponent("DeletePermanently.applescript")
        let content = """
        tell application "Finder"
            set sel to selection
            if sel is {} then
                display dialog "No files selected." buttons {"OK"} default button "OK"
            else
                set fileCount to count of sel
                if fileCount is 1 then
                    set itemName to name of item 1 of sel
                    set msg to "Permanently delete \\\"" & itemName & "\\\"?" & return & return & "This cannot be undone!"
                else
                    set msg to "Permanently delete " & fileCount & " items?" & return & return & "This cannot be undone!"
                end if
                set dlgResult to display dialog msg buttons {"Cancel", "Delete Forever"} default button "Cancel" with icon caution
                if button returned of dlgResult is "Delete Forever" then
                    repeat with f in sel
                        do shell script "rm -rf " & quoted form of POSIX path of (f as alias)
                    end repeat
                end if
            end if
        end tell
        """
        do {
            try FileManager.default.createDirectory(at: scriptDir, withIntermediateDirectories: true)
            try content.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            NSLog("OneDown: Failed to install DeletePermanently script: \(error)")
        }
    }

    private static func enableExtensionViaPluginKit() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-e", "use", "-i", "io.github.onedown-app.OneDown.Extension"]
        do {
            try process.run()
        } catch {
            NSLog("OneDown: Failed to enable extension via pluginkit: \(error)")
        }
    }
}
