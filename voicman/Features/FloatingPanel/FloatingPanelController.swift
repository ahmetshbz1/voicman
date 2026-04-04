import AppKit
import SwiftUI

private final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }
}

@MainActor
final class FloatingPanelController {
    private enum Constants {
        static let size = NSSize(width: 320, height: 74)
        static let cornerRadius: CGFloat = 37
    }

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
            contentRect: NSRect(origin: .zero, size: Constants.size),
            styleMask: [.nonactivatingPanel, .borderless],
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

        let container = NSView(frame: NSRect(origin: .zero, size: Constants.size))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(white: 0.11, alpha: 1).cgColor
        container.layer?.cornerRadius = Constants.cornerRadius
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 0.5
        container.layer?.borderColor = NSColor.white.withAlphaComponent(0.07).cgColor

        let hosting = TransparentHostingView(rootView: rootView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        hosting.layer?.isOpaque = false
        container.addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        panel.contentView = container

        positionAtBottomCenter(panel)
        self.panel = panel
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
