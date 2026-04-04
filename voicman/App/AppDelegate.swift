import AppKit
import AVFoundation

@MainActor
protocol RecordingSettingsProviding {
    var locale: String { get }
    var shouldAutoPaste: Bool { get }
    var shouldAutoCopyFinalText: Bool { get }
}

struct UserDefaultsRecordingSettingsProvider: RecordingSettingsProviding {
    var locale: String {
        UserDefaults.standard.string(forKey: "locale") ?? "tr-TR"
    }

    var shouldAutoPaste: Bool {
        UserDefaults.standard.object(forKey: "autoPaste") as? Bool ?? true
    }

    var shouldAutoCopyFinalText: Bool {
        UserDefaults.standard.object(forKey: "autoCopyFinalText") as? Bool ?? true
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let settingsProvider: RecordingSettingsProviding
    private var hotkeyService: HotkeyServiceProtocol
    private var audioEngine: AudioEngineProtocol
    private var transcriptionEngine: TranscriptionEngineProtocol
    private var pasteboardService: PasteboardServiceProtocol
    private var panelController: FloatingPanelControlling
    private var onboardingController: OnboardingWindowController?
    private var settingsController: SettingsWindowController?
    private var statusItem: NSStatusItem?

    override init() {
        hotkeyService = HotkeyService()
        audioEngine = AudioEngine()
        transcriptionEngine = SpeechTranscriptionEngine()
        pasteboardService = PasteboardService()
        panelController = FloatingPanelController()
        settingsProvider = UserDefaultsRecordingSettingsProvider()
        super.init()
    }

    init(
        hotkeyService: HotkeyServiceProtocol,
        audioEngine: AudioEngineProtocol,
        transcriptionEngine: TranscriptionEngineProtocol,
        pasteboardService: PasteboardServiceProtocol,
        panelController: FloatingPanelControlling,
        settingsProvider: RecordingSettingsProviding
    ) {
        self.hotkeyService = hotkeyService
        self.audioEngine = audioEngine
        self.transcriptionEngine = transcriptionEngine
        self.pasteboardService = pasteboardService
        self.panelController = panelController
        self.settingsProvider = settingsProvider
        super.init()
    }

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
        hotkeyService.unregister()
        audioEngine.stop()
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
        panelController.onButtonTapped = { [weak self] in
            self?.togglePause()
        }
        panelController.onSecondaryButtonTapped = { [weak self] in
            self?.stopRecording()
        }
        panelController.onCloseTapped = { [weak self] in
            self?.cancelRecording()
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

    func bindHotkeyToRecording() {
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
            let state = self.panelController.viewModel.state
            if holdDuration > 0.5 && (state == .recording || state == .paused) {
                self.stopRecording()
            }
        }

        hotkeyService.onEnterPressed = { [weak self] in
            guard let self else { return }
            let state = self.panelController.viewModel.state
            if state == .recording || state == .paused {
                self.stopRecording()
            }
        }

        hotkeyService.onEscapePressed = { [weak self] in
            guard let self else { return }
            let state = self.panelController.viewModel.state
            if state == .recording || state == .paused || state == .transcribing {
                self.cancelRecording()
            }
        }
    }

    // MARK: - Kayıt Akışı

    func startRecording() {
        pasteboardService.beginSession()
        panelController.show()
        panelController.viewModel.transition(to: .recording)
        hotkeyService.registerEnterHotkey()
        hotkeyService.registerEscapeHotkey()
        startAudioCapture()

        transcriptionEngine.startRecognition(locale: settingsProvider.locale) { [weak self] text in
            self?.panelController.viewModel.updateTextFromEngine(text)
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

    func togglePause() {
        switch panelController.viewModel.state {
        case .recording:
            pauseRecording()
        case .paused:
            resumeRecording()
        default:
            break
        }
    }

    func pauseRecording() {
        audioEngine.stop()
        panelController.viewModel.transition(to: .paused)
    }

    func resumeRecording() {
        panelController.show()
        panelController.viewModel.transition(to: .recording)
        startAudioCapture()
    }

    func stopRecording() {
        let isUserEdited = panelController.viewModel.isUserEdited
        let userEditedText = panelController.viewModel.partialText

        panelController.viewModel.transition(to: .transcribing)
        audioEngine.stop()
        hotkeyService.unregisterEnterHotkey()
        hotkeyService.unregisterEscapeHotkey()

        let shouldPaste = settingsProvider.shouldAutoPaste
        let shouldCopy = settingsProvider.shouldAutoCopyFinalText

        transcriptionEngine.finalize { [weak self] result in
            guard let self else { return }
            
            let finalText: String
            switch result {
            case .success(let engineText):
                finalText = isUserEdited ? userEditedText : (engineText.isEmpty ? userEditedText : engineText)
            case .failure(let error):
                let msg = error.localizedDescription
                if isUserEdited {
                    finalText = userEditedText
                } else if msg.contains("No speech detected") || msg.contains("cancelled") {
                    finalText = ""
                } else {
                    self.pasteboardService.cancelSession()
                    self.handleError(error)
                    return
                }
            }

            if !finalText.isEmpty {
                self.pasteboardService.endSession(finalText: finalText, shouldPaste: shouldPaste, shouldCopy: shouldCopy)
                self.panelController.hideAfterDelay(1.5)
            } else {
                self.pasteboardService.cancelSession()
                self.panelController.hide()
            }
        }
    }

    func cancelRecording() {
        audioEngine.stop()
        hotkeyService.unregisterEnterHotkey()
        hotkeyService.unregisterEscapeHotkey()
        transcriptionEngine.cancel()
        pasteboardService.cancelSession()
        panelController.hide()
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
