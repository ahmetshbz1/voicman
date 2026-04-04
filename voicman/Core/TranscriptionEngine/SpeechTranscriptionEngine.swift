import AVFoundation
import Speech
import os.log

/// Apple SFSpeechRecognizer tabanlı, cihaz üzerinde çalışan transkripsiyon motoru.
/// Türkçe (tr-TR) desteği ile M-serisi Neural Engine üzerinde çalışır.
@MainActor
final class SpeechTranscriptionEngine: TranscriptionEngineProtocol {

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var finalCompletion: ((Result<String, Error>) -> Void)?
    private var lastPartialResult: String = ""

    private let log = Logger(subsystem: "com.ahmetshbz.voicman", category: "TranscriptionEngine")

    func requestAuthorization(completion: @MainActor @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                completion(status == .authorized)
            }
        }
    }

    func startRecognition(locale: String, onPartialResult: @MainActor @escaping (String) -> Void) {
        let recognizerLocale = Locale(identifier: locale)
        recognizer = SFSpeechRecognizer(locale: recognizerLocale)

        guard let recognizer, recognizer.isAvailable else {
            log.warning("SFSpeechRecognizer '\(locale)' için hazır değil.")
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // On-device recognition Siri & Dikte açıkken çalışır.
        // Zorlamak yerine destekleniyorsa tercih et, yoksa server-side'a düş.
        // Server-side recognition: Siri/Dikte ayarından bağımsız çalışır,
        // Türkçe için doğruluk daha yüksek.
        request.requiresOnDeviceRecognition = false
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }

                if let result {
                    let text = result.bestTranscription.formattedString
                    self.lastPartialResult = text
                    onPartialResult(text)

                    if result.isFinal {
                        self.deliverFinalResult(.success(text))
                    }
                }

                if let error {
                    let nsError = error as NSError
                    let code = nsError.code
                    // 301 = iptal (normal), 203 = "No speech detected" (sessizce geç)
                    if nsError.domain == "kAFAssistantErrorDomain" && (code == 301 || code == 203) {
                        self.deliverFinalResult(.success(self.lastPartialResult))
                    } else {
                        self.log.error("Transkripsiyon hatası (\(code)): \(error.localizedDescription)")
                        self.deliverFinalResult(.failure(error))
                    }
                }
            }
        }

        log.info("Transkripsiyon başladı (\(locale)).")
    }

    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    func finalize(completion: @MainActor @escaping (Result<String, Error>) -> Void) {
        finalCompletion = completion

        if let request = recognitionRequest {
            // endAudio → SFSpeechRecognizer'ı final sonucu üretmeye zorlar
            request.endAudio()
        } else {
            deliverFinalResult(.success(lastPartialResult))
        }
    }

    // MARK: - Yardımcı

    private func deliverFinalResult(_ result: Result<String, Error>) {
        guard let completion = finalCompletion else { return }
        finalCompletion = nil
        recognitionTask = nil
        recognitionRequest = nil
        lastPartialResult = ""
        completion(result)
    }
}
