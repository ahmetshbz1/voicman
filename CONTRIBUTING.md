# Contributing | Katkı Rehberi

## English

Thanks for considering a contribution to Voicman.

### Before You Start

- Open an issue for large changes before implementing them.
- Keep pull requests focused.
- Preserve the current architecture split: `App`, `Core`, `Features`.
- Match the existing code style and naming patterns.

### Development Setup

1. Open `voicman.xcodeproj` in Xcode.
2. Select the `voicman` scheme.
3. Configure your Apple development team if signing is required.
4. Run the app and complete onboarding permissions.

### Validation

Run the project build before opening a pull request:

```bash
xcodebuild -project voicman.xcodeproj -scheme voicman -configuration Debug -derivedDataPath build build
```

Current repository status:

- No dedicated automated test target is present yet
- No external package dependency is required

### Pull Request Expectations

- Describe the problem and the solution clearly.
- Include screenshots or a short screen recording for UI changes.
- Mention permission-related behavior if your change affects microphone, speech recognition, or accessibility.
- Keep unrelated refactors out of feature or bug fix pull requests.

### Code Guidelines

- Prefer small, focused files.
- Avoid dead code and unused imports.
- Do not add noisy debug logging to production code.
- Preserve permission flows and onboarding clarity.
- Avoid introducing third-party dependencies unless there is a strong reason.

### Commit Messages

Use concise, descriptive commit messages. Examples:

- `feat: add shortcut recorder validation`
- `fix: prevent partial text overwrite during manual editing`
- `docs: expand onboarding and privacy documentation`

### Reporting Bugs

Please include:

- macOS version
- Xcode version
- Steps to reproduce
- Expected result
- Actual result
- Whether microphone, speech recognition, and accessibility permissions were granted

---

## Türkçe

Voicman’a katkı yapmayı düşündüğün için teşekkürler.

### Başlamadan Önce

- Büyük değişikliklerde implementasyondan önce issue aç.
- Pull request’leri odaklı tut.
- Mevcut `App`, `Core`, `Features` mimari ayrımını koru.
- Var olan kod stili ve isimlendirme düzenini takip et.

### Geliştirme Ortamı

1. `voicman.xcodeproj` dosyasını Xcode ile aç.
2. `voicman` scheme’ini seç.
3. Gerekirse Apple development team ayarını yap.
4. Uygulamayı çalıştır ve onboarding izinlerini tamamla.

### Doğrulama

Pull request açmadan önce proje build’ini çalıştır:

```bash
xcodebuild -project voicman.xcodeproj -scheme voicman -configuration Debug -derivedDataPath build build
```

Repo şu anda:

- Ayrı bir otomatik test target’ı içermiyor
- Harici package bağımlılığı gerektirmiyor

### Pull Request Beklentileri

- Problemi ve çözümü net şekilde açıkla.
- UI değişikliklerinde ekran görüntüsü veya kısa ekran kaydı ekle.
- Değişiklik mikrofon, konuşma tanıma veya erişilebilirlik davranışını etkiliyorsa bunu belirt.
- Özellik veya bug fix PR’larına ilgisiz refactor’lar ekleme.

### Kod Rehberi

- Küçük ve odaklı dosyaları tercih et.
- Dead code ve kullanılmayan import bırakma.
- Production koda gürültülü debug log ekleme.
- İzin akışlarını ve onboarding netliğini bozma.
- Güçlü bir gerekçe yoksa üçüncü parti bağımlılık ekleme.

### Commit Mesajları

Kısa ve açıklayıcı commit mesajları kullan. Örnekler:

- `feat: add shortcut recorder validation`
- `fix: prevent partial text overwrite during manual editing`
- `docs: expand onboarding and privacy documentation`

### Bug Raporlarken

Şunları mutlaka ekle:

- macOS sürümü
- Xcode sürümü
- Yeniden üretme adımları
- Beklenen sonuç
- Gerçek sonuç
- Mikrofon, konuşma tanıma ve erişilebilirlik izinlerinin durumu
