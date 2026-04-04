import XCTest
import AVFoundation
@testable import voicman

@MainActor
final class MockHotkeyService: HotkeyServiceProtocol {
    var onHotkeyDown: (() -> Void)?
    var onHotkeyUp: ((TimeInterval) -> Void)?
    var onEnterPressed: (() -> Void)?
    var onEscapePressed: (() -> Void)?

    private(set) var unregisterCallCount = 0
    private(set) var registerEnterHotkeyCallCount = 0
    private(set) var registerEscapeHotkeyCallCount = 0
    private(set) var unregisterEnterHotkeyCallCount = 0
    private(set) var unregisterEscapeHotkeyCallCount = 0

    func unregister() {
        unregisterCallCount += 1
    }

    func registerEnterHotkey() {
        registerEnterHotkeyCallCount += 1
    }

    func registerEscapeHotkey() {
        registerEscapeHotkeyCallCount += 1
    }

    func unregisterEnterHotkey() {
        unregisterEnterHotkeyCallCount += 1
    }

    func unregisterEscapeHotkey() {
        unregisterEscapeHotkeyCallCount += 1
    }
}

@MainActor
final class MockAudioEngine: AudioEngineProtocol {
    private(set) var startCaptureCallCount = 0
    private(set) var stopCallCount = 0

    func startCapture(
        onBuffer: @MainActor @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void,
        onError: @MainActor @escaping (Error) -> Void
    ) {
        startCaptureCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }
}

@MainActor
final class MockTranscriptionEngine: TranscriptionEngineProtocol {
    private(set) var requestAuthorizationCallCount = 0
    private(set) var startRecognitionLocales: [String] = []
    private(set) var appendBufferCallCount = 0
    private(set) var cancelCallCount = 0
    var partialResultHandler: ((String) -> Void)?
    var finalizeCompletion: ((Result<String, Error>) -> Void)?

    func requestAuthorization(completion: @MainActor @escaping (Bool) -> Void) {
        requestAuthorizationCallCount += 1
        completion(true)
    }

    func startRecognition(locale: String, onPartialResult: @MainActor @escaping (String) -> Void) {
        startRecognitionLocales.append(locale)
        partialResultHandler = onPartialResult
    }

    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        appendBufferCallCount += 1
    }

    func cancel() {
        cancelCallCount += 1
    }

    func finalize(completion: @MainActor @escaping (Result<String, Error>) -> Void) {
        finalizeCompletion = completion
    }
}

@MainActor
final class MockPasteboardService: PasteboardServiceProtocol {
    struct EndSessionCall: Equatable {
        let finalText: String
        let shouldPaste: Bool
        let shouldCopy: Bool
    }

    private(set) var copiedTexts: [String] = []
    private(set) var copyAndPasteTexts: [String] = []
    private(set) var beginSessionCallCount = 0
    private(set) var endSessionCalls: [EndSessionCall] = []
    private(set) var cancelSessionCallCount = 0

    func copy(text: String) {
        copiedTexts.append(text)
    }

    func copyAndPaste(text: String) {
        copyAndPasteTexts.append(text)
    }

    func beginSession() {
        beginSessionCallCount += 1
    }

    func endSession(finalText: String, shouldPaste: Bool, shouldCopy: Bool) {
        endSessionCalls.append(.init(finalText: finalText, shouldPaste: shouldPaste, shouldCopy: shouldCopy))
    }

    func cancelSession() {
        cancelSessionCallCount += 1
    }
}

@MainActor
final class MockFloatingPanelController: FloatingPanelControlling {
    let viewModel = RecordingViewModel()
    var onButtonTapped: (() -> Void)?
    var onSecondaryButtonTapped: (() -> Void)?
    var onCloseTapped: (() -> Void)?

    private(set) var showCallCount = 0
    private(set) var hideCallCount = 0
    private(set) var hideAfterDelayCalls: [Double] = []

    func show() {
        showCallCount += 1
    }

    func hide() {
        hideCallCount += 1
        viewModel.hide()
    }

    func hideAfterDelay(_ seconds: Double) {
        hideAfterDelayCalls.append(seconds)
    }
}

struct StubRecordingSettingsProvider: RecordingSettingsProviding {
    let locale: String
    let shouldAutoPaste: Bool
    let shouldAutoCopyFinalText: Bool
}

enum TestErrors: LocalizedError {
    case noSpeechDetected
    case genericFailure

    var errorDescription: String? {
        switch self {
        case .noSpeechDetected:
            return "No speech detected"
        case .genericFailure:
            return "Generic failure"
        }
    }
}
