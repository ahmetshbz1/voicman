import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController {

    private let popover: NSPopover
    private var globalClickMonitor: Any?

    init() {
        let popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.animates = true
        popover.contentSize = NSSize(width: 420, height: 380)
        self.popover = popover
    }

    func toggle(relativeTo button: NSStatusBarButton) {
        if popover.isShown {
            close()
        } else {
            show(relativeTo: button)
        }
    }

    func show(relativeTo button: NSStatusBarButton) {
        popover.contentViewController = NSHostingController(rootView: SettingsView())
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startMonitoringOutsideClicks()
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }

    func close() {
        stopMonitoringOutsideClicks()
        popover.performClose(nil)
        popover.contentViewController = nil
    }

    private func startMonitoringOutsideClicks() {
        stopMonitoringOutsideClicks()
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.close()
            }
        }
    }

    private func stopMonitoringOutsideClicks() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
    }
}
