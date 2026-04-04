import AppKit
import AVFoundation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var hotkeyService: HotkeyService!
    private var audioEngine: AudioEngine!
    private var transcriptionEngine: SpeechTranscriptionEngine!
    private var pasteboardService: PasteboardService!
    private var panelController: FloatingPanelController!
    private var onboardingController: OnboardingWindowController?
    private var settingsController: SettingsWindowController?
    private var statusItem: NSStatusItem?
    private var typeDebounce: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if CommandLine.arguments.contains("--reset-onboarding") {
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
        }

        let completed = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if completed {
            launchMainApp()
        } else {
            showOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyService?.unregister()
        audioEngine?.stop()
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        NSApp.setActivationPolicy(.regular)
        let controller = OnboardingWindowController()
        controller.onComplete = { [weak self] in
            self?.onboardingController?.close()
            self?.onboardingController = nil
            NSApp.setActivationPolicy(.accessory)
            self?.launchMainApp()
        }
        onboardingController = controller
        controller.show()
    }

    // MARK: - Ana Uygulama

    private func launchMainApp() {
        bootstrapServices()
        setupStatusBar()
        bindHotkeyToRecording()
    }

    private func bootstrapServices() {
        pasteboardService = PasteboardService()
        transcriptionEngine = SpeechTranscriptionEngine()
        audioEngine = AudioEngine()
        panelController = FloatingPanelController()
        hotkeyService = HotkeyService()

        panelController.onButtonTapped = { [weak self] in
            self?.togglePause()
        }
        panelController.onSecondaryButtonTapped = { [weak self] in
            self?.stopRecording()
        }

        transcriptionEngine.requestAuthorization { _ in }
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voicman")

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Ayarlar...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Çıkış", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController()
        }
        settingsController?.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Hotkey

    private func bindHotkeyToRecording() {
        hotkeyService.onHotkeyDown = { [weak self] in
            guard let self else { return }
            switch self.panelController.viewModel.state {
            case .idle:
                self.startRecording()
            case .recording:
                self.stopRecording()
            case .paused:
                self.resumeRecording()
            default:         break
            }
        }

        hotkeyService.onHotkeyUp = { [weak self] holdDuration in
            guard let self else { return }
            if holdDuration > 0.5 {
                self.stopRecording()
            }
        }
    }

    // MARK: - Kayıt Akışı

    private func startRecording() {
        let locale = UserDefaults.standard.string(forKey: "locale") ?? "tr-TR"

        pasteboardService.beginSession()
        panelController.show()
        panelController.viewModel.transition(to: .recording)
        startAudioCapture()

        transcriptionEngine.startRecognition(locale: locale) { [weak self] text in
            self?.panelController.viewModel.partialText = text
            self?.debouncedType(text)
        }
    }

    private func startAudioCapture() {
        audioEngine.startCapture { @MainActor [weak self] buffer, _ in
            self?.transcriptionEngine.appendBuffer(buffer)
            self?.panelController.viewModel.audioLevel = Self.rms(buffer)
        } onError: { @MainActor [weak self] error in
            self?.handleError(error)
        }
    }

    private func togglePause() {
        switch panelController.viewModel.state {
        case .recording:
            pauseRecording()
        case .paused:
            resumeRecording()
        default:
            break
        }
    }

    private func pauseRecording() {
        typeDebounce?.cancel()
        audioEngine.stop()
        panelController.viewModel.transition(to: .paused)
    }

    private func resumeRecording() {
        panelController.show()
        panelController.viewModel.transition(to: .recording)
        startAudioCapture()
    }

    private func debouncedType(_ text: String) {
        typeDebounce?.cancel()
        typeDebounce = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            self?.pasteboardService.typePartial(text: text)
        }
    }

    private func stopRecording() {
        typeDebounce?.cancel()
        panelController.viewModel.transition(to: .transcribing)
        audioEngine.stop()

        let shouldPaste = UserDefaults.standard.object(forKey: "autoPaste") as? Bool ?? true

        transcriptionEngine.finalize { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let text) where !text.isEmpty:
                self.pasteboardService.endSession(finalText: text, shouldPaste: shouldPaste)
                self.panelController.hideAfterDelay()
            case .success:
                self.pasteboardService.cancelSession()
                self.panelController.hide()
            case .failure(let error):
                let msg = error.localizedDescription
                if msg.contains("No speech detected") || msg.contains("cancelled") {
                    self.pasteboardService.cancelSession()
                    self.panelController.hide()
                } else {
                    self.pasteboardService.cancelSession()
                    self.handleError(error)
                }
            }
        }
    }

    // MARK: - Yardımcı

    private static func rms(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        let frames = Int(buffer.frameLength)
        let sum = (0..<frames).reduce(Float(0)) { $0 + data[$1] * data[$1] }
        return min(sqrt(sum / Float(frames)) * 8, 1.0)
    }

    private func handleError(_ error: Error) {
        panelController.viewModel.transition(to: .error(error.localizedDescription))
        Task {
            try? await Task.sleep(for: .seconds(2))
            panelController.hide()
        }
    }
}
