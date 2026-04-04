import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {

    private var window: NSWindow?
    private let viewModel = OnboardingViewModel()

    var onComplete: (() -> Void)? {
        get { viewModel.onComplete }
        set { viewModel.onComplete = newValue }
    }

    func show() {
        let content = OnboardingView(viewModel: viewModel)

        // FirstMouseHostingView: ilk tıklamada buton aksiyonunu tetikler,
        // pencere fokus aktivasyonunu beklemez
        let hostingView = FirstMouseHostingView(rootView: content)
        hostingView.wantsLayer = true

        let hosting = NSViewController()
        hosting.view = hostingView

        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .black
        window.isOpaque = true
        window.setContentSize(NSSize(width: 520, height: 420))
        window.center()
        window.isMovableByWindowBackground = true
        window.level = .normal

        self.window = window

        // TCC diyalogu arkada kalmasın — izin öncesi window geri, sonra öne
        viewModel.onWillShowPermissionDialog = { [weak window] in
            window?.orderBack(nil)
        }
        viewModel.onDidFinishPermissionDialog = { [weak window] in
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window?.close()
        window = nil
    }
}

// MARK: - First Mouse Hosting View

/// acceptsFirstMouse override'ı ile ilk tıklama pencere aktivasyonuna değil,
/// doğrudan SwiftUI buton aksiyonuna iletilir — mikrofon/izin diyaloglarının
/// ilk tıklamada açılmaması sorununu çözer
private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
