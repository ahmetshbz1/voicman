import XCTest
@testable import voicman

@MainActor
final class AppDelegateTests: XCTestCase {
    func test_bindHotkeyToRecording_whenIdle_hotkeyDownStartsRecordingFlow() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        sut.bindHotkeyToRecording()

        hotkeyService.onHotkeyDown?()

        XCTAssertEqual(panelController.viewModel.state, .recording)
        XCTAssertEqual(pasteboardService.beginSessionCallCount, 1)
        XCTAssertEqual(audioEngine.startCaptureCallCount, 1)
        XCTAssertEqual(transcriptionEngine.startRecognitionLocales, ["en-US"])
    }

    func test_bindHotkeyToRecording_whenPaused_hotkeyDownResumesRecording() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: MockTranscriptionEngine(),
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        panelController.viewModel.transition(to: .paused)
        sut.bindHotkeyToRecording()

        hotkeyService.onHotkeyDown?()

        XCTAssertEqual(panelController.showCallCount, 1)
        XCTAssertEqual(panelController.viewModel.state, .recording)
        XCTAssertEqual(audioEngine.startCaptureCallCount, 1)
    }

    func test_bindHotkeyToRecording_whenIdle_hotkeyUpDoesNotTriggerStopFlow() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        sut.bindHotkeyToRecording()

        hotkeyService.onHotkeyUp?(0.8)

        XCTAssertEqual(panelController.viewModel.state, .idle)
        XCTAssertEqual(audioEngine.stopCallCount, 0)
        XCTAssertNil(transcriptionEngine.finalizeCompletion)
        XCTAssertEqual(pasteboardService.endSessionCalls.count, 0)
        XCTAssertEqual(pasteboardService.cancelSessionCallCount, 0)
    }

    func test_bindHotkeyToRecording_whenRecording_shortHotkeyUpDoesNotStopFlow() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        panelController.viewModel.transition(to: .recording)
        sut.bindHotkeyToRecording()

        hotkeyService.onHotkeyUp?(0.2)

        XCTAssertEqual(panelController.viewModel.state, .recording)
        XCTAssertEqual(audioEngine.stopCallCount, 0)
        XCTAssertNil(transcriptionEngine.finalizeCompletion)
    }

    func test_bindHotkeyToRecording_whenRecording_longHotkeyUpStopsFlow() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        panelController.viewModel.transition(to: .recording)
        sut.bindHotkeyToRecording()

        hotkeyService.onHotkeyUp?(0.8)

        XCTAssertEqual(panelController.viewModel.state, .transcribing)
        XCTAssertEqual(audioEngine.stopCallCount, 1)
        XCTAssertNotNil(transcriptionEngine.finalizeCompletion)
    }

    func test_bindHotkeyToRecording_whenRecording_enterStopsRecordingFlow() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        panelController.viewModel.transition(to: .recording)
        sut.bindHotkeyToRecording()

        hotkeyService.onEnterPressed?()

        XCTAssertEqual(panelController.viewModel.state, .transcribing)
        XCTAssertEqual(audioEngine.stopCallCount, 1)
        XCTAssertNotNil(transcriptionEngine.finalizeCompletion)
    }

    func test_bindHotkeyToRecording_whenRecording_hotkeyDownStopsRecordingFlow() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        panelController.viewModel.transition(to: .recording)
        sut.bindHotkeyToRecording()

        hotkeyService.onHotkeyDown?()

        XCTAssertEqual(panelController.viewModel.state, .transcribing)
        XCTAssertEqual(audioEngine.stopCallCount, 1)
        XCTAssertNotNil(transcriptionEngine.finalizeCompletion)
    }

    func test_bindHotkeyToRecording_whenTranscribing_escapeCancelsRecording() {
        let hotkeyService = MockHotkeyService()
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: MockAudioEngine(),
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        panelController.viewModel.transition(to: .transcribing)
        sut.bindHotkeyToRecording()

        hotkeyService.onEscapePressed?()

        XCTAssertEqual(transcriptionEngine.cancelCallCount, 1)
        XCTAssertEqual(pasteboardService.cancelSessionCallCount, 1)
        XCTAssertEqual(panelController.hideCallCount, 1)
    }

    func test_startRecording_beginsSessionShowsPanelRegistersHotkeysStartsRecognitionAndCapture() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let settings = StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: false, shouldAutoCopyFinalText: true)
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: settings
        )

        sut.startRecording()

        XCTAssertEqual(pasteboardService.beginSessionCallCount, 1)
        XCTAssertEqual(panelController.showCallCount, 1)
        XCTAssertEqual(panelController.viewModel.state, .recording)
        XCTAssertEqual(hotkeyService.registerEnterHotkeyCallCount, 1)
        XCTAssertEqual(hotkeyService.registerEscapeHotkeyCallCount, 1)
        XCTAssertEqual(transcriptionEngine.startRecognitionLocales, ["en-US"])
        XCTAssertEqual(audioEngine.startCaptureCallCount, 1)
    }

    func test_startRecording_partialResultUpdatesPanelText() {
        let transcriptionEngine = MockTranscriptionEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: MockHotkeyService(),
            audioEngine: MockAudioEngine(),
            transcriptionEngine: transcriptionEngine,
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )

        sut.startRecording()
        transcriptionEngine.partialResultHandler?("merhaba")

        XCTAssertEqual(panelController.viewModel.partialText, "merhaba")
    }

    func test_startRecording_partialResultDoesNotOverwriteUserEditedText() {
        let transcriptionEngine = MockTranscriptionEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: MockHotkeyService(),
            audioEngine: MockAudioEngine(),
            transcriptionEngine: transcriptionEngine,
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "en-US", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )

        sut.startRecording()
        panelController.viewModel.partialText = "manuel"
        panelController.viewModel.isUserEdited = true
        transcriptionEngine.partialResultHandler?("engine")

        XCTAssertEqual(panelController.viewModel.partialText, "manuel")
    }

    func test_stopRecording_withSuccessfulFinalization_endsPasteboardSessionAndSchedulesHide() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let settings = StubRecordingSettingsProvider(locale: "tr-TR", shouldAutoPaste: true, shouldAutoCopyFinalText: false)
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: settings
        )
        sut.startRecording()

        sut.stopRecording()
        transcriptionEngine.finalizeCompletion?(Result<String, Error>.success("çıktı"))

        XCTAssertEqual(panelController.viewModel.state, .transcribing)
        XCTAssertEqual(audioEngine.stopCallCount, 1)
        XCTAssertEqual(hotkeyService.unregisterEnterHotkeyCallCount, 1)
        XCTAssertEqual(hotkeyService.unregisterEscapeHotkeyCallCount, 1)
        XCTAssertEqual(
            pasteboardService.endSessionCalls,
            [.init(finalText: "çıktı", shouldPaste: true, shouldCopy: false)]
        )
        XCTAssertEqual(panelController.hideAfterDelayCalls, [1.5])
    }

    func test_stopRecording_prefersUserEditedTextOverEngineResult() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "tr-TR", shouldAutoPaste: false, shouldAutoCopyFinalText: true)
        )

        sut.startRecording()
        panelController.viewModel.partialText = "manuel düzeltme"
        panelController.viewModel.isUserEdited = true

        sut.stopRecording()
        transcriptionEngine.finalizeCompletion?(Result<String, Error>.success("engine text"))

        XCTAssertEqual(
            pasteboardService.endSessionCalls,
            [.init(finalText: "manuel düzeltme", shouldPaste: false, shouldCopy: true)]
        )
    }

    func test_stopRecording_withNoSpeechError_cancelsPasteboardSessionAndHidesPanel() {
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: MockHotkeyService(),
            audioEngine: MockAudioEngine(),
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "tr-TR", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )
        sut.startRecording()

        sut.stopRecording()
        transcriptionEngine.finalizeCompletion?(Result<String, Error>.failure(TestErrors.noSpeechDetected))

        XCTAssertEqual(pasteboardService.cancelSessionCallCount, 1)
        XCTAssertTrue(pasteboardService.endSessionCalls.isEmpty)
        XCTAssertEqual(panelController.hideCallCount, 1)
    }

    func test_cancelRecording_stopsServicesAndHidesPanel() {
        let hotkeyService = MockHotkeyService()
        let audioEngine = MockAudioEngine()
        let transcriptionEngine = MockTranscriptionEngine()
        let pasteboardService = MockPasteboardService()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: hotkeyService,
            audioEngine: audioEngine,
            transcriptionEngine: transcriptionEngine,
            pasteboardService: pasteboardService,
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "tr-TR", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )

        sut.cancelRecording()

        XCTAssertEqual(audioEngine.stopCallCount, 1)
        XCTAssertEqual(hotkeyService.unregisterEnterHotkeyCallCount, 1)
        XCTAssertEqual(hotkeyService.unregisterEscapeHotkeyCallCount, 1)
        XCTAssertEqual(transcriptionEngine.cancelCallCount, 1)
        XCTAssertEqual(pasteboardService.cancelSessionCallCount, 1)
        XCTAssertEqual(panelController.hideCallCount, 1)
    }

    func test_pauseRecording_stopsAudioAndSetsPausedState() {
        let audioEngine = MockAudioEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: MockHotkeyService(),
            audioEngine: audioEngine,
            transcriptionEngine: MockTranscriptionEngine(),
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "tr-TR", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )

        sut.pauseRecording()

        XCTAssertEqual(audioEngine.stopCallCount, 1)
        XCTAssertEqual(panelController.viewModel.state, .paused)
        XCTAssertEqual(panelController.viewModel.audioLevel, 0)
    }

    func test_resumeRecording_showsPanelStartsCaptureAndSetsRecordingState() {
        let audioEngine = MockAudioEngine()
        let panelController = MockFloatingPanelController()
        let sut = AppDelegate(
            hotkeyService: MockHotkeyService(),
            audioEngine: audioEngine,
            transcriptionEngine: MockTranscriptionEngine(),
            pasteboardService: MockPasteboardService(),
            panelController: panelController,
            settingsProvider: StubRecordingSettingsProvider(locale: "tr-TR", shouldAutoPaste: true, shouldAutoCopyFinalText: true)
        )

        sut.resumeRecording()

        XCTAssertEqual(panelController.showCallCount, 1)
        XCTAssertEqual(panelController.viewModel.state, .recording)
        XCTAssertEqual(audioEngine.startCaptureCallCount, 1)
    }
}
