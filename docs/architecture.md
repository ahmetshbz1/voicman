# Architecture | Mimari

## English

Voicman is structured as a native macOS application with a clear split between app orchestration, reusable services, and user-facing features.

## High-Level Structure

```text
voicman/
├── App/
├── Core/
└── Features/
```

### `App`

Application lifecycle and composition root.

- `voicmanApp.swift`: SwiftUI entry point
- `AppDelegate.swift`: startup flow, service bootstrap, status bar setup, onboarding handoff, recording orchestration

### `Core`

Infrastructure and system-facing services.

- `AudioEngine/AudioEngine.swift`: microphone capture with `AVAudioEngine`
- `TranscriptionEngine/SpeechTranscriptionEngine.swift`: speech-to-text with `SFSpeechRecognizer`
- `HotkeyService/HotkeyService.swift`: global hotkey registration through Carbon
- `PasteboardService/PasteboardService.swift`: clipboard session handling and optional simulated paste
- `*Protocol.swift` files: service abstractions

### `Features`

User-facing modules.

- `Onboarding/`: first-run permissions and shortcut setup
- `FloatingPanel/`: live recording UI, partial text, state transitions
- `Settings/`: shortcut, language, and behavior preferences

## Runtime Flow

1. `AppDelegate` checks `hasCompletedOnboarding`.
2. If onboarding is incomplete, `OnboardingWindowController` is shown.
3. After onboarding, services are bootstrapped and the menu bar item is created.
4. Global hotkey events are mapped to start, pause, resume, or stop recording.
5. `AudioEngine` captures microphone input.
6. `SpeechTranscriptionEngine` emits partial and final text.
7. `FloatingPanelController` reflects live state to the user.
8. `PasteboardService` copies and optionally pastes the final result.

## Design Notes

- Hybrid SwiftUI + AppKit architecture
- `@MainActor` is used broadly to keep UI state consistent
- User preferences are stored in `UserDefaults` and `@AppStorage`
- Accessibility is optional at onboarding time, but required for automatic paste automation
- The app is configured as a menu bar/accessory-style experience instead of a traditional document app

## Important Technical Constraints

- Global hotkeys rely on Carbon APIs
- Automatic paste relies on Accessibility trust and synthetic keyboard events
- The app currently has no dedicated automated test target
- The project currently targets `MACOSX_DEPLOYMENT_TARGET = 26.1`
- The project uses generated Info.plist values from Xcode build settings

---

## Türkçe

Voicman; uygulama orkestrasyonu, yeniden kullanılabilir servisler ve kullanıcıya dönük özellikler arasında net ayrım yapan native bir macOS uygulamasıdır.

## Üst Seviye Yapı

```text
voicman/
├── App/
├── Core/
└── Features/
```

### `App`

Uygulama yaşam döngüsü ve composition root.

- `voicmanApp.swift`: SwiftUI giriş noktası
- `AppDelegate.swift`: başlangıç akışı, servis bootstrap’i, status bar kurulumu, onboarding geçişi, kayıt orkestrasyonu

### `Core`

Altyapı ve sistemle konuşan servisler.

- `AudioEngine/AudioEngine.swift`: `AVAudioEngine` ile mikrofon capture
- `TranscriptionEngine/SpeechTranscriptionEngine.swift`: `SFSpeechRecognizer` ile speech-to-text
- `HotkeyService/HotkeyService.swift`: Carbon üzerinden global hotkey kaydı
- `PasteboardService/PasteboardService.swift`: pano oturumu yönetimi ve isteğe bağlı simüle yapıştırma
- `*Protocol.swift` dosyaları: servis soyutlamaları

### `Features`

Kullanıcıya dönük modüller.

- `Onboarding/`: ilk açılış izinleri ve kısayol kurulumu
- `FloatingPanel/`: canlı kayıt arayüzü, partial text, durum geçişleri
- `Settings/`: kısayol, dil ve davranış tercihleri

## Çalışma Zamanı Akışı

1. `AppDelegate`, `hasCompletedOnboarding` değerini kontrol eder.
2. Onboarding tamamlanmamışsa `OnboardingWindowController` gösterilir.
3. Onboarding sonrası servisler ayağa kaldırılır ve menü çubuğu öğesi oluşturulur.
4. Global hotkey olayları kayıt başlatma, duraklatma, devam ettirme veya bitirmeye eşlenir.
5. `AudioEngine` mikrofondan ses alır.
6. `SpeechTranscriptionEngine` partial ve final metni üretir.
7. `FloatingPanelController`, canlı durumu kullanıcıya yansıtır.
8. `PasteboardService`, final sonucu kopyalar ve isteğe bağlı olarak yapıştırır.

## Tasarım Notları

- Hibrit SwiftUI + AppKit mimarisi
- UI state tutarlılığı için yaygın biçimde `@MainActor` kullanılır
- Kullanıcı tercihleri `UserDefaults` ve `@AppStorage` içinde tutulur
- Erişilebilirlik onboarding sırasında opsiyoneldir; ancak otomatik yapıştırma için gereklidir
- Uygulama klasik document app yerine menu bar/accessory deneyimi olarak yapılandırılmıştır

## Önemli Teknik Kısıtlar

- Global hotkey’ler Carbon API’lerine dayanır
- Otomatik yapıştırma, Accessibility trust ve sentetik klavye olaylarına dayanır
- Uygulamanın şu anda ayrı bir otomatik test target’ı yoktur
- Proje şu anda `MACOSX_DEPLOYMENT_TARGET = 26.1` hedefler
- Proje, Xcode build settings üzerinden generate edilen Info.plist değerlerini kullanır
