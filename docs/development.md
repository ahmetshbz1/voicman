# Development Guide | Geliştirme Rehberi

## English

## Local Setup

1. Open `voicman.xcodeproj` in Xcode.
2. Select the `voicman` scheme.
3. Set a valid Apple development team if Xcode asks for signing.
4. Build and run.
5. Complete the onboarding permissions flow.

## Build

```bash
xcodebuild -project voicman.xcodeproj -scheme voicman -configuration Debug -derivedDataPath build build
```

## Reset Onboarding

If you want to repeat the first-run experience:

```bash
open build/Build/Products/Debug/voicman.app --args --reset-onboarding
```

When running from Xcode, add `--reset-onboarding` to the scheme arguments instead.

## Current Persistence Keys

- `hasCompletedOnboarding`
- `hotkeyKeyCode`
- `hotkeyModifiers`
- `autoPaste`
- `autoCopyFinalText`
- `locale`

## Development Tips

- Verify microphone and speech permissions from System Settings if recognition appears inactive.
- Verify Accessibility permission if automatic paste does not work.
- Keep UI changes consistent across onboarding, floating panel, and settings.
- Do not assume clipboard ownership remains stable after simulated paste; the project intentionally preserves prior clipboard content in some flows.

## Validation Status

Current repository observations:

- One app target: `voicman`
- No separate test target is defined in the Xcode project
- No external package manager dependency is configured

Before submitting changes, at minimum run the Debug build command and verify the app launches.

---

## Türkçe

## Yerel Kurulum

1. `voicman.xcodeproj` dosyasını Xcode ile aç.
2. `voicman` scheme’ini seç.
3. Xcode imzalama isterse geçerli bir Apple development team ayarla.
4. Build ve Run yap.
5. Onboarding izin akışını tamamla.

## Build

```bash
xcodebuild -project voicman.xcodeproj -scheme voicman -configuration Debug -derivedDataPath build build
```

## Onboarding Sıfırlama

İlk kullanım deneyimini yeniden görmek istersen:

```bash
open build/Build/Products/Debug/voicman.app --args --reset-onboarding
```

Xcode’dan çalıştırıyorsan `--reset-onboarding` argümanını scheme arguments bölümüne ekle.

## Mevcut Kalıcılık Anahtarları

- `hasCompletedOnboarding`
- `hotkeyKeyCode`
- `hotkeyModifiers`
- `autoPaste`
- `autoCopyFinalText`
- `locale`

## Geliştirme İpuçları

- Tanıma pasif görünüyorsa Sistem Ayarları üzerinden mikrofon ve konuşma izinlerini doğrula.
- Otomatik yapıştırma çalışmıyorsa Accessibility iznini doğrula.
- UI değişikliklerinde onboarding, floating panel ve settings arasında tutarlılığı koru.
- Simüle yapıştırma sonrası pano sahipliğinin sabit kalacağını varsayma; proje bazı akışlarda önceki pano içeriğini bilinçli olarak geri yükler.

## Doğrulama Durumu

Repodaki mevcut gözlemler:

- Tek uygulama target’ı: `voicman`
- Xcode projesinde ayrı bir test target’ı tanımlı değil
- Harici package manager bağımlılığı yapılandırılmamış

Değişiklik göndermeden önce en azından Debug build komutunu çalıştır ve uygulamanın açıldığını doğrula.
