// Stay Awake: a menu bar coffee cup that keeps the Mac from idle-sleeping.
//
// It holds a PreventUserIdleSystemSleep power assertion (the same mechanism
// `caffeinate -i` uses) while on. The display may still sleep; nothing in the
// system power settings is changed, and quitting releases the assertion.

import AppKit
import IOKit.pwr_mgt
import ServiceManagement

final class SleepAssertion {
    private let type: String
    private let name: String
    private var id: IOPMAssertionID = 0
    private(set) var isActive = false

    init(type: String, name: String) {
        self.type = type
        self.name = name
    }

    func enable() -> Bool {
        guard !isActive else { return true }
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            name as CFString,
            &id)
        isActive = result == kIOReturnSuccess
        return isActive
    }

    func disable() {
        guard isActive else { return }
        IOPMAssertionRelease(id)
        isActive = false
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let assertion = SleepAssertion(type: kIOPMAssertPreventUserIdleSystemSleep,
                                           name: "Stay Awake menu bar app")
    // Keeping the display on also avoids the lock screen that macOS shows
    // when "require password after the display is turned off" is set.
    private let screenAssertion = SleepAssertion(type: kIOPMAssertPreventUserIdleDisplaySleep,
                                                 name: "Stay Awake menu bar app (screen)")
    private var statusItem: NSStatusItem!
    private var offTimer: Timer?
    private var awakeUntil: Date?
    private let defaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        defaults.register(defaults: ["enabled": true, "keepScreenOn": true])
        setAwake(defaults.bool(forKey: "enabled"), until: nil)
        syncLaunchAtLogin()
    }

    func applicationWillTerminate(_ notification: Notification) {
        assertion.disable()
        screenAssertion.disable()
    }

    // MARK: State

    private func setAwake(_ on: Bool, until: Date?) {
        offTimer?.invalidate()
        offTimer = nil
        awakeUntil = nil
        if on {
            if !assertion.enable() {
                NSSound.beep()
            }
            if let until, assertion.isActive {
                awakeUntil = until
                offTimer = Timer.scheduledTimer(withTimeInterval: until.timeIntervalSinceNow, repeats: false) { [weak self] _ in
                    self?.setAwake(false, until: nil)
                }
            }
        } else {
            assertion.disable()
        }
        syncScreenAssertion()
        // A timed session is temporary; only remember plain on/off choices.
        if until == nil {
            defaults.set(assertion.isActive, forKey: "enabled")
        }
        updateIcon()
    }

    private func syncScreenAssertion() {
        if assertion.isActive && defaults.bool(forKey: "keepScreenOn") {
            _ = screenAssertion.enable()
        } else {
            screenAssertion.disable()
        }
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let on = assertion.isActive
        let image = NSImage(systemSymbolName: on ? "cup.and.saucer.fill" : "cup.and.saucer",
                            accessibilityDescription: on ? "Stay Awake: on" : "Stay Awake: off")
        image?.isTemplate = true
        button.image = image
        button.appearsDisabled = !on
        button.toolTip = "Stay Awake: \(statusText())\nClick to toggle · Right-click for options"
    }

    private func statusText() -> String {
        guard assertion.isActive else { return "off (Mac sleeps normally)" }
        let screen = screenAssertion.isActive ? "screen stays on" : "screen may turn off"
        guard let until = awakeUntil else { return "on, \(screen)" }
        let f = DateFormatter()
        f.timeStyle = .short
        return "on until \(f.string(from: until)), \(screen)"
    }

    // MARK: Clicks and menu

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            statusItem.menu = buildMenu()
            sender.performClick(nil)
            statusItem.menu = nil
        } else {
            setAwake(!assertion.isActive, until: nil)
        }
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let status = NSMenuItem(title: "Stay Awake is \(statusText())", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let toggle = NSMenuItem(title: "Stay Awake", action: #selector(toggleFromMenu), keyEquivalent: "")
        toggle.target = self
        toggle.state = assertion.isActive ? .on : .off
        menu.addItem(toggle)

        let forItem = NSMenuItem(title: "Keep Awake For", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for hours in [1, 2, 4, 8] {
            let item = NSMenuItem(title: hours == 1 ? "1 Hour" : "\(hours) Hours",
                                  action: #selector(keepAwakeFor(_:)), keyEquivalent: "")
            item.target = self
            item.tag = hours
            sub.addItem(item)
        }
        forItem.submenu = sub
        menu.addItem(forItem)

        let screen = NSMenuItem(title: "Keep Screen On", action: #selector(toggleKeepScreenOn), keyEquivalent: "")
        screen.target = self
        screen.state = defaults.bool(forKey: "keepScreenOn") ? .on : .off
        menu.addItem(screen)
        menu.addItem(.separator())

        let login = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.target = self
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Stay Awake", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        return menu
    }

    @objc private func toggleFromMenu() {
        setAwake(!assertion.isActive, until: nil)
    }

    @objc private func toggleKeepScreenOn() {
        defaults.set(!defaults.bool(forKey: "keepScreenOn"), forKey: "keepScreenOn")
        syncScreenAssertion()
        updateIcon()
    }

    @objc private func keepAwakeFor(_ sender: NSMenuItem) {
        setAwake(true, until: Date().addingTimeInterval(TimeInterval(sender.tag) * 3600))
    }

    @objc private func toggleLaunchAtLogin() {
        setLaunchAtLogin(SMAppService.mainApp.status != .enabled, quietly: false)
    }

    // MARK: Launch at login

    // The choice is kept in "launchAtLogin" and re-applied on every launch:
    // each rebuild re-signs the app, which can leave a stale login item.
    // The first launch asks instead.
    private func syncLaunchAtLogin() {
        if defaults.object(forKey: "launchAtLogin") == nil {
            askLaunchAtLogin()
        } else if defaults.bool(forKey: "launchAtLogin") {
            setLaunchAtLogin(true, quietly: true)
        }
    }

    private func askLaunchAtLogin() {
        activate()
        let alert = NSAlert()
        alert.messageText = "Open Stay Awake when you log in?"
        alert.informativeText = "Stay Awake will start in the menu bar each time you log in. You can change this later from the menu (right-click the cup)."
        alert.addButton(withTitle: "Open at Login")
        alert.addButton(withTitle: "Not Now")
        setLaunchAtLogin(alert.runModal() == .alertFirstButtonReturn, quietly: false)
    }

    private func setLaunchAtLogin(_ on: Bool, quietly: Bool) {
        defaults.set(on, forKey: "launchAtLogin")
        do {
            if on {
                try SMAppService.mainApp.register()
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            guard !quietly else { return }
            activate()
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = "\(error.localizedDescription)\n\nYou can add Stay Awake in System Settings → General → Login Items instead."
            alert.runModal()
            return
        }
        if on && SMAppService.mainApp.status == .requiresApproval && !quietly {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    private func activate() {
        if #available(macOS 14, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@main
enum StayAwakeMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
