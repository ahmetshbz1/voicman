import SwiftUI
import Carbon.HIToolbox

struct SettingsView: View {

    @AppStorage("hotkeyKeyCode")   private var hotkeyKeyCode: Int = Int(kVK_Space)
    @AppStorage("hotkeyModifiers") private var hotkeyModifiers: Int = Int(optionKey)
    @AppStorage("autoPaste")       private var autoPaste: Bool = true
    @AppStorage("autoCopyFinalText") private var autoCopyFinalText: Bool = true
    @AppStorage("locale")          private var locale: String = "tr-TR"

    @State private var recKeyCode: UInt32 = UInt32(kVK_Space)
    @State private var recModifiers: UInt32 = UInt32(optionKey)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.06))
            ScrollView {
                VStack(spacing: 20) {
                    hotkeySection
                    languageSection
                    behaviorSection
                }
                .padding(24)
            }
        }
        .frame(width: 420, height: 380)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            recKeyCode   = UInt32(hotkeyKeyCode)
            recModifiers = UInt32(hotkeyModifiers)
        }
    }

    // MARK: - Başlık

    private var header: some View {
        HStack {
            Text("Ayarlar")
                .font(.system(size: 16, weight: .bold))
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Kısayol

    private var hotkeySection: some View {
        SettingsSection(title: "Kısayol Tuşu") {
            ShortcutRecorderView(
                keyCode:   $recKeyCode,
                modifiers: $recModifiers
            )
            .onChange(of: recKeyCode) { oldValue, newValue in
                hotkeyKeyCode = Int(newValue)
            }
            .onChange(of: recModifiers) { oldValue, newValue in
                hotkeyModifiers = Int(newValue)
            }
        }
    }

    // MARK: - Dil

    private var languageSection: some View {
        SettingsSection(title: "Transkripsiyon Dili") {
            HStack {
                Text("Dil")
                    .font(.system(size: 13))
                Spacer()
                Picker("", selection: $locale) {
                    Text("Türkçe").tag("tr-TR")
                    Text("English").tag("en-US")
                    Text("Deutsch").tag("de-DE")
                    Text("Français").tag("fr-FR")
                    Text("Español").tag("es-ES")
                }
                .labelsHidden()
                .frame(width: 140)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Davranış

    private var behaviorSection: some View {
        SettingsSection(title: "Davranış") {
            VStack(spacing: 0) {
                settingsToggle(
                    title: "Otomatik Yapıştır",
                    subtitle: "Transkripsiyon sonrası metni aktif uygulamaya yapıştır",
                    isOn: $autoPaste
                )
                Divider().padding(.leading, 16)
                settingsToggle(
                    title: "Final Metni Kopyala",
                    subtitle: "Kayıt bittiğinde son metni panoya kopyala",
                    isOn: $autoCopyFinalText
                )
            }
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Section

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }
}
