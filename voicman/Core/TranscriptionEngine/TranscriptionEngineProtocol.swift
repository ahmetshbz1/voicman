import AVFoundation

/// Konuşma → metin dönüşümünü yönetir.
@MainActor
protocol TranscriptionEngineProtocol: AnyObject {
    func requestAuthorization(completion: @MainActor @escaping (Bool) -> Void)
    /// Gerçek zamanlı tanımayı başlatır.
    func startRecognition(locale: String, onPartialResult: @MainActor @escaping (String) -> Void)
    /// Ses buffer'ı ekler (AudioEngine'den akış).
    func appendBuffer(_ buffer: AVAudioPCMBuffer)
    /// Tanımayı sonlandırır ve nihai metni döner.
    func finalize(completion: @MainActor @escaping (Result<String, Error>) -> Void)
}
