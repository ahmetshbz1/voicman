import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController {

    let viewModel = RecordingViewModel()
    var onButtonTapped: (() -> Void)?
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    init() {
        setupPanel()
    }

    func show() {
        hideTask?.cancel()
        hideTask = nil
        panel?.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
        viewModel.hide()
    }

    func hideAfterDelay(_ seconds: Double = 1.5) {
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.hide()
        }
    }

    // MARK: - Panel Kurulumu

    private func setupPanel() {
        let rootView = RecordingView(viewModel: viewModel) { [weak self] in
            self?.onButtonTapped?()
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.isMovableByWindowBackground = false

        let hosting = NSHostingView(rootView: rootView)
        hosting.wantsLayer = true
        panel.contentView = hosting

        // Tüm katmanları şeffaf yap
        Self.clearAllLayers(hosting)

        positionAtBottomCenter(panel)
        self.panel = panel

        // Layout sonrası tekrar temizle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let hosting = self?.panel?.contentView {
                Self.clearAllLayers(hosting)
            }
        }
    }

    private static func clearAllLayers(_ view: NSView) {
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
        view.layer?.isOpaque = false
        for sub in view.subviews {
            clearAllLayers(sub)
        }
    }

    private func positionAtBottomCenter(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelSize = panel.frame.size
        let x = screenFrame.midX - panelSize.width / 2
        let y = screenFrame.minY + 28
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
