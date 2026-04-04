import AVFoundation
import Speech
import AppKit
import SwiftUI
import Combine
import Carbon.HIToolbox
import os.log

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case microphone
    case speechRecognition
    case hotkey
    case accessibility
    case complete
}

@MainActor
final class OnboardingViewModel: ObservableObject {

    @Published var step: OnboardingStep = .welcome
    @Published var micGranted: Bool = false
    @Published var speechGranted: Bool = false
    @Published var accessibilityGranted: Bool = false
    @Published var isRequesting: Bool = false

    // Kayıt edilen kısayol — varsayılan ⌥Space
    @Published var hotkeyKeyCode: UInt32 = UInt32(kVK_Space)
    @Published var hotkeyModifiers: UInt32 = UInt32(optionKey)

    private let log = Logger(subsystem: "com.ahmetshbz.voicman", category: "Onboarding")
    var onComplete: (() -> Void)?

    /// TCC diyalogu görünmeden önce window'u arkaya al
    var onWillShowPermissionDialog: (() -> Void)?
    /// TCC diyalogu kapandıktan sonra window'u öne getir
    var onDidFinishPermissionDialog: (() -> Void)?

    init() {
        loadSavedHotkey()
        refreshPermissionStatuses()
    }

    // MARK: - İzinler

    func refreshPermissionStatuses() {
        micGranted        = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        speechGranted     = SFSpeechRecognizer.authorizationStatus() == .authorized
        accessibilityGranted = AXIsProcessTrusted()
    }

    func requestMicrophone() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        log.info("requestMicrophone çağrıldı — status: \(status.rawValue)")

        if status == .denied || status == .restricted {
            log.info("Mikrofon izni reddedilmiş/kısıtlı, Sistem Ayarları açılıyor")
            openSystemSettings(url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
            return
        }

        isRequesting = true
        let hasWillShow = onWillShowPermissionDialog != nil
        log.info("onWillShowPermissionDialog bağlı mı: \(hasWillShow)")
        onWillShowPermissionDialog?()
        log.info("Window orderBack çağrıldı, TCC diyalogu bekleniyor")

        AVAudioApplication.requestRecordPermission { granted in
            Task { @MainActor in
                self.log.info("requestRecordPermission sonucu: \(granted)")
                self.micGranted   = granted
                self.isRequesting = false
                self.onDidFinishPermissionDialog?()
            }
        }
    }

    func requestSpeech() {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .denied || status == .restricted {
            openSystemSettings(url: "x-apple.systempreferences:com.apple.preference.security?Privacy_SpeechRecognition")
            return
        }
        isRequesting = true
        onWillShowPermissionDialog?()
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.speechGranted = status == .authorized
                self.isRequesting  = false
                self.onDidFinishPermissionDialog?()
            }
        }
    }

    func openAccessibilitySettings() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        openSystemSettings(url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    // MARK: - Kısayol

    func hotkeyDisplayString() -> String {
        guard hotkeyKeyCode != 0 else { return "⌥ Space" }
        var parts: [String] = []
        if hotkeyModifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if hotkeyModifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if hotkeyModifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if hotkeyModifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(keyCodeLabel(hotkeyKeyCode))
        return parts.joined()
    }

    private func loadSavedHotkey() {
        if let kc = UserDefaults.standard.object(forKey: "hotkeyKeyCode") as? Int {
            hotkeyKeyCode = UInt32(kc)
        }
        if let mod = UserDefaults.standard.object(forKey: "hotkeyModifiers") as? Int {
            hotkeyModifiers = UInt32(mod)
        }
    }

    private func keyCodeLabel(_ kc: UInt32) -> String {
        switch Int(kc) {
        case kVK_Space:  return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab:    return "⇥"
        default:         return "Key\(kc)"
        }
    }

    // MARK: - Akış

    func next() {
        let all = OnboardingStep.allCases
        guard let current = all.firstIndex(of: step), current + 1 < all.count else {
            finish()
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            step = all[current + 1]
        }
    }

    func finish() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete?()
    }

    private func openSystemSettings(url: String) {
        guard let settingsURL = URL(string: url) else { return }
        NSWorkspace.shared.open(settingsURL)
    }
}
