# Voicman

English | Türkçe

Voicman is a macOS menu bar dictation app that starts recording with a global shortcut, transcribes speech with Apple Speech, and can paste the final text into the active app.

Voicman, global kısayol ile kayıt başlatan, Apple Speech ile sesi metne çeviren ve sonucu aktif uygulamaya yapıştırabilen bir macOS menü çubuğu dikte uygulamasıdır.

## English

### Features

- Menu bar app with no regular main window during normal use
- Global hotkey support (`Option + Space` by default)
- Short press to toggle recording
- Press-and-hold for push-to-talk style usage
- Live floating panel with partial transcription
- Manual text editing before final submission
- Automatic paste into the active app when Accessibility permission is granted
- Clipboard-safe fallback behavior when auto-paste is disabled
- Onboarding flow for microphone, speech recognition, and accessibility permissions
- Settings for hotkey, language, auto-paste, and auto-copy

### Tech Stack

- Swift
- SwiftUI + AppKit
- AVFoundation
- Speech framework
- Carbon HotKey APIs
- Accessibility APIs

### Requirements

- macOS app project opened with Xcode
- The project is currently configured with `MACOSX_DEPLOYMENT_TARGET = 26.1`
- Microphone permission is required
- Speech Recognition permission is required
- Accessibility permission is optional, but required for automatic paste simulation

### Project Structure

```text
voicman/
├── App/           # app lifecycle, bootstrap, status bar orchestration
├── Core/          # audio, transcription, hotkey, pasteboard services
├── Features/      # onboarding, floating panel, settings UI
└── Assets.xcassets
```

### How It Works

1. The app launches as an accessory/menu bar app.
2. On first launch, onboarding collects required permissions and the preferred hotkey.
3. The global hotkey starts audio capture.
4. `AVAudioEngine` streams audio buffers into `SFSpeechRecognizer`.
5. Partial transcription is shown in the floating panel.
6. When recording stops, the final text is copied and optionally pasted into the active app.

### Run in Xcode

1. Open `voicman.xcodeproj` in Xcode.
2. Select the `voicman` scheme.
3. Build and run the app.
4. Grant requested permissions during onboarding.

If local signing fails, set your own Apple development team in Xcode and keep automatic signing enabled.

### Build from CLI

```bash
xcodebuild -project voicman.xcodeproj -scheme voicman -configuration Debug -derivedDataPath build build
```

### Development Notes

- There is currently no dedicated test target in the repository.
- The app stores onboarding and settings values in `UserDefaults`.
- You can reset the onboarding flow with:

```bash
open build/Build/Products/Debug/voicman.app --args --reset-onboarding
```

If you run from Xcode directly, add `--reset-onboarding` to the scheme arguments instead.

### Permissions and Privacy

- Microphone: required to capture audio
- Speech Recognition: required to transcribe speech
- Accessibility: required only for simulated `Cmd+V` paste into other apps

Voicman uses Apple system frameworks for speech recognition. See `docs/privacy-and-permissions.md` for details.

### Documentation

- `docs/architecture.md`
- `docs/development.md`
- `docs/privacy-and-permissions.md`
- `CONTRIBUTING.md`
- `SECURITY.md`

### Contributing

Contributions are welcome. Please read `CONTRIBUTING.md` before opening a pull request.

### License

This project is licensed under the MIT License. See `LICENSE`.

---

## Türkçe

### Özellikler

- Normal kullanımda klasik ana pencere göstermeyen menü çubuğu uygulaması
- Global kısayol desteği (varsayılan `Option + Space`)
- Kısa basma ile kayıt aç/kapat
- Basılı tutma ile push-to-talk benzeri kullanım
- Canlı kısmi transkripsiyon gösteren floating panel
- Göndermeden önce manuel metin düzenleme
- Erişilebilirlik izni varsa aktif uygulamaya otomatik yapıştırma
- Otomatik yapıştırma kapalıyken panoyu koruyan fallback davranışı
- Mikrofon, konuşma tanıma ve erişilebilirlik izinleri için onboarding akışı
- Kısayol, dil, otomatik yapıştırma ve otomatik kopyalama ayarları

### Teknoloji Yığını

- Swift
- SwiftUI + AppKit
- AVFoundation
- Speech framework
- Carbon HotKey API’leri
- Accessibility API’leri

### Gereksinimler

- Xcode ile açılan bir macOS uygulama projesi
- Proje şu anda `MACOSX_DEPLOYMENT_TARGET = 26.1` ile yapılandırılmış durumda
- Mikrofon izni zorunlu
- Konuşma tanıma izni zorunlu
- Erişilebilirlik izni isteğe bağlıdır; ancak otomatik yapıştırma için gerekir

### Proje Yapısı

```text
voicman/
├── App/           # uygulama yaşam döngüsü, bootstrap, status bar orkestrasyonu
├── Core/          # audio, transcription, hotkey, pasteboard servisleri
├── Features/      # onboarding, floating panel, settings arayüzü
└── Assets.xcassets
```

### Çalışma Akışı

1. Uygulama accessory/menu bar app olarak başlar.
2. İlk açılışta onboarding gerekli izinleri ve tercih edilen kısayolu toplar.
3. Global kısayol ses kaydını başlatır.
4. `AVAudioEngine`, ses buffer’larını `SFSpeechRecognizer` içine aktarır.
5. Kısmi transkripsiyon floating panel üzerinde gösterilir.
6. Kayıt durduğunda final metin kopyalanır ve isteğe bağlı olarak aktif uygulamaya yapıştırılır.

### Xcode ile Çalıştırma

1. `voicman.xcodeproj` dosyasını Xcode ile açın.
2. `voicman` scheme’ini seçin.
3. Build ve Run yapın.
4. Onboarding sırasında istenen izinleri verin.

Yerel imzalama hatası alırsanız Xcode içinde kendi Apple development team’inizi seçin ve automatic signing’i açık tutun.

### CLI ile Build

```bash
xcodebuild -project voicman.xcodeproj -scheme voicman -configuration Debug -derivedDataPath build build
```

### Geliştirme Notları

- Repoda şu anda ayrı bir test target’ı bulunmuyor.
- Uygulama onboarding ve ayar değerlerini `UserDefaults` içinde saklar.
- Onboarding akışını sıfırlamak için:

```bash
open build/Build/Products/Debug/voicman.app --args --reset-onboarding
```

Xcode’dan doğrudan çalıştırıyorsanız `--reset-onboarding` argümanını scheme arguments kısmına ekleyin.

### İzinler ve Gizlilik

- Mikrofon: ses yakalamak için zorunlu
- Konuşma Tanıma: sesi metne çevirmek için zorunlu
- Erişilebilirlik: sadece diğer uygulamalara simüle `Cmd+V` yapıştırması için gerekli

Voicman, konuşma tanıma için Apple sistem framework’lerini kullanır. Ayrıntılar için `docs/privacy-and-permissions.md` dosyasına bakın.

### Dokümantasyon

- `docs/architecture.md`
- `docs/development.md`
- `docs/privacy-and-permissions.md`
- `CONTRIBUTING.md`
- `SECURITY.md`

### Katkı

Katkılar memnuniyetle karşılanır. Pull request açmadan önce `CONTRIBUTING.md` dosyasını okuyun.

### Lisans

Bu proje MIT lisansı ile lisanslanmıştır. Ayrıntılar için `LICENSE` dosyasına bakın.
