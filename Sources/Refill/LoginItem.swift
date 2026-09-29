import ServiceManagement

enum LoginItem {
    static var status: SMAppService.Status { SMAppService.mainApp.status }
    static var isOn: Bool { status == .enabled }

    static func set(_ on: Bool) {
        do { on ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
        catch { NSLog("Refill login item: \(error)") }
    }

    /// First launch from /Applications: opt in by default (toggle lives in Settings).
    static func enableOnFirstRun() {
        let key = "loginItemInitialized"
        guard !UserDefaults.standard.bool(forKey: key), Bundle.main.bundlePath.hasPrefix("/Applications") else { return }
        UserDefaults.standard.set(true, forKey: key)
        set(true)
    }
}
