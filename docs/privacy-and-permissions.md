# Privacy and Permissions | Gizlilik ve İzinler

## English

Voicman requires system permissions because it records audio, performs speech recognition, and can paste text into other applications.

## Required Permissions

### Microphone

Used to capture live audio from the user.

### Speech Recognition

Used to convert captured speech into text through Apple Speech APIs.

## Optional Permission

### Accessibility

Used only when Voicman needs to simulate `Cmd+V` in the active application after transcription completes.

If Accessibility permission is not granted:

- transcription can still complete
- final text can still be copied
- automatic paste into the active app will not occur

## Clipboard Behavior

Voicman stores the current clipboard text at the beginning of a recording session.

Depending on settings:

- it may replace the clipboard with the final transcript
- it may temporarily paste the transcript and then restore the previous clipboard content
- it may restore the previous clipboard if the recording is canceled

## Data Handling Notes

- Settings are stored locally with `UserDefaults`
- The app uses Apple platform speech recognition APIs
- This repository currently does not document any custom remote backend or separate telemetry pipeline

Users should still review Apple’s own platform privacy behavior for microphone and speech recognition services on their macOS version.

---

## Türkçe

Voicman; ses kaydettiği, konuşma tanıma yaptığı ve diğer uygulamalara metin yapıştırabildiği için sistem izinleri ister.

## Zorunlu İzinler

### Mikrofon

Kullanıcının canlı sesini yakalamak için kullanılır.

### Konuşma Tanıma

Yakalanan sesi Apple Speech API’leri üzerinden metne çevirmek için kullanılır.

## Opsiyonel İzin

### Erişilebilirlik

Sadece transkripsiyon tamamlandıktan sonra aktif uygulamada simüle `Cmd+V` yapmak gerektiğinde kullanılır.

Erişilebilirlik izni verilmezse:

- transkripsiyon yine tamamlanabilir
- final metin yine kopyalanabilir
- aktif uygulamaya otomatik yapıştırma gerçekleşmez

## Pano Davranışı

Voicman, kayıt oturumu başında mevcut pano metnini saklar.

Ayar durumuna göre:

- panoyu final transkripsiyon ile değiştirebilir
- transkripsiyonu geçici olarak yapıştırıp önceki pano içeriğini geri yükleyebilir
- kayıt iptal edilirse önceki panoyu geri getirebilir

## Veri İşleme Notları

- Ayarlar yerel olarak `UserDefaults` içinde tutulur
- Uygulama Apple platform speech recognition API’lerini kullanır
- Bu repo şu anda ayrı bir özel backend veya telemetry hattı dokümante etmez

Yine de kullanıcılar kendi macOS sürümlerindeki mikrofon ve konuşma tanıma servislerinin gizlilik davranışı için Apple dokümantasyonunu ayrıca incelemelidir.
