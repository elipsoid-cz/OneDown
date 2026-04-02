import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    private static let scriptDirectoryURL: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Scripts/io.github.onedown-app.OneDown.Extension")
    }()

    private static let scriptURL: URL = {
        scriptDirectoryURL.appendingPathComponent("DeletePermanently.applescript")
    }()

    private static let scriptContent = """
    tell application "Finder"
        set sel to selection
        if sel is {} then
            display dialog "No files selected." buttons {"OK"} default button "OK"
        else
            set fileCount to count of sel
            if fileCount is 1 then
                set itemName to name of item 1 of sel
                set msg to "Permanently delete \\"" & itemName & "\\"?" & return & return & "This cannot be undone!"
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

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        installScript()
    }

    // MARK: - Script Installation

    private func installScript() {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: Self.scriptDirectoryURL, withIntermediateDirectories: true)
            try Self.scriptContent.write(to: Self.scriptURL, atomically: true, encoding: .utf8)
        } catch {
            NSLog("OneDown: Failed to install DeletePermanently script: \(error)")
        }
    }

    // MARK: - Toolbar Item

    override var toolbarItemName: String { "Delete Forever" }

    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "trash.slash", accessibilityDescription: "Permanently delete selected files")
            ?? NSImage(named: NSImage.stopProgressTemplateName)!
    }

    override var toolbarItemToolTip: String { "Permanently Delete Selected Files" }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        if menuKind == .toolbarItemMenu {
            DispatchQueue.global(qos: .userInitiated).async {
                self.deletePermanently()
            }
        }
        return NSMenu()
    }

    // MARK: - Deletion

    private func deletePermanently() {
        guard FileManager.default.fileExists(atPath: Self.scriptURL.path) else {
            NSLog("OneDown: DeletePermanently.applescript not found")
            return
        }
        do {
            let task = try NSUserAppleScriptTask(url: Self.scriptURL)
            let semaphore = DispatchSemaphore(value: 0)
            task.execute(withAppleEvent: nil) { result, error in
                if let error = error {
                    NSLog("OneDown: AppleScript error: \(error)")
                }
                semaphore.signal()
            }
            _ = semaphore.wait(timeout: .now() + 30.0)
        } catch {
            NSLog("OneDown: Failed to load script task: \(error)")
        }
    }
}
