import SwiftUI
import Combine

// MARK: - Ana View

struct OnboardingView: View {

    @ObservedObject var viewModel: OnboardingViewModel
    private let accessibilityTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(
                colors: [Color.white.opacity(0.03), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(viewModel.step)
                Spacer()
                bottomBar
            }
            .padding(40)
        }
        .frame(width: 520, height: 440)
        .onReceive(accessibilityTimer) { _ in
            if viewModel.step == .accessibility { viewModel.checkAccessibility() }
        }
    }

    // MARK: - Adım İçeriği

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .welcome:
            welcomeStep
        case .microphone:
            permissionStep(
                icon: "mic.fill", iconColor: .red,
                title: "Mikrofon Erişimi",
                description: "Sesinizi kaydedebilmek için mikrofon erişimi gerekiyor.",
                granted: viewModel.micGranted,
                buttonLabel: "İzin Ver",
                action: { viewModel.requestMicrophone() }
            )
        case .speechRecognition:
            permissionStep(
                icon: "waveform", iconColor: .blue,
                title: "Konuşma Tanıma",
                description: "Apple'ın konuşma tanıma servisi Türkçe'yi yüksek doğrulukla metne dönüştürür.",
                granted: viewModel.speechGranted,
                buttonLabel: "İzin Ver",
                action: { viewModel.requestSpeech() }
            )
        case .hotkey:
            hotkeyStep
        case .accessibility:
            accessibilityStep
        case .complete:
            completeStep
        }
    }

    // MARK: - Adımlar

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            iconCircle(systemName: "mic.fill", color: .red)
            VStack(spacing: 10) {
                Text("Voicman'a Hoş Geldiniz")
                    .font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                Text("⌥Space ile her uygulamada Türkçe sesli dikte.\nSadece birkaç izin gerekiyor.")
                    .font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }
        }
    }

    private func permissionStep(
        icon: String, iconColor: Color,
        title: String, description: String,
        granted: Bool, buttonLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(granted ? 0.25 : 0.15))
                    .frame(width: 88, height: 88)
                    .animation(.easeInOut, value: granted)
                if granted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40)).foregroundStyle(iconColor)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium)).foregroundStyle(iconColor)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: granted)

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }

            if !granted {
                OnboardingButton(label: buttonLabel, color: iconColor, isLoading: viewModel.isRequesting, action: action)
            }
        }
    }

    private var hotkeyStep: some View {
        VStack(spacing: 24) {
            iconCircle(systemName: "command.square.fill", color: .orange)

            VStack(spacing: 10) {
                Text("Kısayol Tuşu")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                Text("Ses kaydını başlatmak/durdurmak için\nglobal kısayol tuşunu kaydet.")
                    .font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }

            ShortcutRecorderView(
                keyCode:   $viewModel.hotkeyKeyCode,
                modifiers: $viewModel.hotkeyModifiers
            )
            .padding(.horizontal, 4)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange.opacity(0.7))
                Text("Escape ile kaydı iptal edebilirsin")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
            }
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(viewModel.accessibilityGranted ? 0.25 : 0.15))
                    .frame(width: 88, height: 88)
                    .animation(.easeInOut, value: viewModel.accessibilityGranted)
                if viewModel.accessibilityGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40)).foregroundStyle(.purple)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 34, weight: .medium)).foregroundStyle(.purple)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.accessibilityGranted)

            VStack(spacing: 10) {
                Text("Erişilebilirlik İzni")
                    .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                Text("Transkripsiyon tamamlandığında metni aktif\nuygulamaya otomatik yapıştırmak için gerekli.\nAtlayabilirsin — sadece panoya kopyalar.")
                    .font(.system(size: 14)).foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center).lineSpacing(4)
            }

            if !viewModel.accessibilityGranted {
                OnboardingButton(label: "Sistem Ayarlarını Aç", color: .purple) {
                    viewModel.openAccessibilitySettings()
                }
            }
        }
    }

    private var completeStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green.opacity(0.3), .teal.opacity(0.1)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 88, height: 88)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44)).foregroundStyle(.green)
            }

            VStack(spacing: 10) {
                Text("Hazırsın!")
                    .font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                VStack(spacing: 6) {
                    hotkeyHint(key: viewModel.hotkeyDisplayString(), desc: "Kısa bas: toggle modu")
                    hotkeyHint(key: viewModel.hotkeyDisplayString(), desc: "Basılı tut: push-to-talk")
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Yardımcı View'lar

    private func iconCircle(systemName: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [color.opacity(0.3), color.opacity(0.1)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 88, height: 88)
            Image(systemName: systemName)
                .font(.system(size: 38, weight: .medium)).foregroundStyle(color)
        }
    }

    private func hotkeyHint(key: String, desc: String) -> some View {
        HStack(spacing: 10) {
            Text(key)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .foregroundStyle(.white.opacity(0.8))
            Text(desc)
                .font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Alt Bar

    private var bottomBar: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(OnboardingStep.allCases, id: \.self) { s in
                    Circle()
                        .fill(s == viewModel.step ? Color.white : Color.white.opacity(0.2))
                        .frame(width: s == viewModel.step ? 8 : 6, height: s == viewModel.step ? 8 : 6)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.step)
                }
            }
            Spacer()
            HStack(spacing: 12) {
                if canSkip {
                    Button("Atla") { viewModel.next() }
                        .buttonStyle(ScaleButtonStyle())
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.35))
                        .focusEffectDisabled()
                }
                OnboardingButton(
                    label: primaryButtonLabel,
                    color: primaryButtonEnabled ? .white : .white.opacity(0.15),
                    textColor: primaryButtonEnabled ? .black : .white.opacity(0.4),
                    enabled: primaryButtonEnabled,
                    action: handlePrimaryAction
                )
            }
        }
    }

    private var canSkip: Bool {
        switch viewModel.step {
        case .microphone, .speechRecognition, .accessibility: return true
        default: return false
        }
    }

    private var primaryButtonLabel: String {
        switch viewModel.step {
        case .welcome:           return "Başla"
        case .microphone:        return viewModel.micGranted ? "Devam" : "Bekliyor..."
        case .speechRecognition: return viewModel.speechGranted ? "Devam" : "Bekliyor..."
        case .hotkey:            return "Devam"
        case .accessibility:     return "Devam"
        case .complete:          return "Voicman'ı Başlat"
        }
    }

    private var primaryButtonEnabled: Bool {
        switch viewModel.step {
        case .microphone:        return viewModel.micGranted
        case .speechRecognition: return viewModel.speechGranted
        default:                 return true
        }
    }

    private func handlePrimaryAction() {
        if viewModel.step == .complete { viewModel.finish() }
        else { viewModel.next() }
    }
}

// MARK: - Özel Buton Stili (scale efekti + focus ring yok)

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            // Default SwiftUI highlight efektini kapat
            .contentShape(Rectangle())
    }
}

// MARK: - Onboarding Aksiyonu Butonu

private struct OnboardingButton: View {
    let label: String
    let color: Color
    var textColor: Color = .white
    var isLoading: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView().scaleEffect(0.7).tint(textColor)
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(textColor)
            }
            .padding(.horizontal, 22).padding(.vertical, 10)
            .background(color)
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .focusEffectDisabled()
        .disabled(!enabled || isLoading)
    }
}
