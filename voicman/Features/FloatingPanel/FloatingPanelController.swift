import AppKit
import SwiftUI
import Combine

private final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            (window as? LongPressDraggablePanel)?.onEscape?()
            return
        }
        super.keyDown(with: event)
    }
}

private final class LongPressDraggablePanel: NSPanel {
    var onLongPress: (() -> Void)?
    var onDragEnded: (() -> Void)?
    var onEscape: (() -> Void)?
    var longPressDelay: TimeInterval = 0.35

    private var dragWorkItem: DispatchWorkItem?
    private var isDragInProgress = false
    var dynamicCanBecomeKey: Bool = false

    override var canBecomeKey: Bool { dynamicCanBecomeKey }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            scheduleLongPress(for: event)
            super.sendEvent(event)
        case .leftMouseUp:
            cancelLongPress()
            if isDragInProgress {
                onDragEnded?()
            }
            isDragInProgress = false
            super.sendEvent(event)
        default:
            super.sendEvent(event)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }
        super.keyDown(with: event)
    }

    private func scheduleLongPress(for event: NSEvent) {
        cancelLongPress()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, !self.isDragInProgress else { return }
            self.isDragInProgress = true
            self.onLongPress?()
            self.performDrag(with: event)
            self.isDragInProgress = false
        }

        dragWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + longPressDelay, execute: workItem)
    }

    private func cancelLongPress() {
        dragWorkItem?.cancel()
        dragWorkItem = nil
    }
}

@MainActor
final class FloatingPanelController {
    private enum Constants {
        static let size = NSSize(width: 292, height: 66)
        static let cornerRadius: CGFloat = 33
    }

    let viewModel = RecordingViewModel()
    var onButtonTapped: (() -> Void)?
    var onSecondaryButtonTapped: (() -> Void)?
    var onCloseTapped: (() -> Void)?
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

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
        let rootView = RecordingView(
            viewModel: viewModel,
            onTap: { [weak self] in self?.onButtonTapped?() },
            onSecondaryTap: { [weak self] in self?.onSecondaryButtonTapped?() },
            onCloseTap: { [weak self] in self?.onCloseTapped?() }
        )

        let panel = LongPressDraggablePanel(
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
        panel.acceptsMouseMovedEvents = true
        panel.isMovableByWindowBackground = false
        panel.onLongPress = { [weak self] in
            self?.performLongPressHaptic()
            self?.viewModel.isDragging = true
        }
        panel.onDragEnded = { [weak self] in
            self?.viewModel.isDragging = false
        }
        panel.onEscape = { [weak self] in
            self?.onCloseTapped?()
        }

        let container = NSView(frame: NSRect(origin: .zero, size: Constants.size))
        container.wantsLayer = true
        container.autoresizingMask = [.width, .height]
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
        panel.initialFirstResponder = hosting

        positionAtBottomCenter(panel)
        self.panel = panel

        viewModel.$isExpanded
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] expanded in
                self?.animatePanelSize(expanded: expanded)
            }
            .store(in: &cancellables)
    }

    private func animatePanelSize(expanded: Bool) {
        guard let panel = panel as? LongPressDraggablePanel else { return }
        
        panel.dynamicCanBecomeKey = expanded
        if expanded {
            panel.makeKey()
        } else {
            panel.resignKey()
            NSApp.deactivate()
        }
        
        let newSize = expanded ? NSSize(width: 380, height: 200) : Constants.size
        var frame = panel.frame
        
        frame.origin.x -= (newSize.width - frame.width) / 2
        frame.size = newSize
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        }, completionHandler: nil)
    }

    private func performLongPressHaptic() {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
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
