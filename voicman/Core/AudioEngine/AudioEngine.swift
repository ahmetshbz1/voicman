import AVFoundation
import os.log

@MainActor
final class AudioEngine: AudioEngineProtocol {

    private let engine = AVAudioEngine()
    private let log = Logger(subsystem: "com.ahmetshbz.voicman", category: "AudioEngine")
    private var isRunning = false

    func startCapture(
        onBuffer: @MainActor @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void,
        onError: @MainActor @escaping (Error) -> Void
    ) {
        guard !isRunning else { return }

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, time in
            // AVAudioEngine tap'i arka planda çalışır — MainActor'a geçir
            Task { @MainActor in
                onBuffer(buffer, time)
            }
        }

        do {
            engine.prepare()
            try engine.start()
            isRunning = true
            log.info("Ses yakalama başladı.")
        } catch {
            inputNode.removeTap(onBus: 0)
            log.error("AVAudioEngine başlatılamadı: \(error.localizedDescription)")
            Task { @MainActor in onError(error) }
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        log.info("Ses yakalama durduruldu.")
    }
}
