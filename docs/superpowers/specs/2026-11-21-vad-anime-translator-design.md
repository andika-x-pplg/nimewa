# Design Doc: Penerjemah Otomatis Bahasa Jepang ke Indonesia Berbasis Voice Activity Detection (VAD)

**Tanggal:** 21 November 2026  
**Status:** Approved by User  
**Topik:** Fitur Penerjemah Teks Otomatis (Live Japanese-to-Indonesian Audio Translation) pada Pemutar Video Anime Nimeva  

---

## 1. Intent & Latar Belakang (The Why)
Pengguna menginginkan pengalaman menonton anime yang lebih imersif dan akurat dengan sistem **Penerjemah Teks Otomatis**. Pada subtitle statis konvensional, penonton sering kali mendapati teks muncul mendahului dialog atau tetap menggantung saat karakter sudah selesai berbicara.

Fitur ini bertindak sebagai penerjemah langsung (*AI Translator*) yang:
1. Mendeteksi kapan karakter anime berbicara di audio aslinya (*voice onset*).
2. Menampilkan teks terjemahan bahasa Indonesia yang sesuai dengan apa yang diucapkan karakter.
3. Menghilangkan teks secara instan saat karakter berhenti berbicara (*voice offset / silence*).

---

## 2. Goals, Non-Goals, & Anti-Goals

### Goals
- **Voice-Activity Synchronized Display**: Teks terjemahan bahasa Indonesia muncul persis di detik saat karakter berbicara dan langsung hilang seketika saat dialog berakhir (durasi jeda hening tidak menampilkan teks).
- **Akurasi Kontekstual Karakter**: Terjemahan mencantumkan nama penutur/karakter (misal: *Tanjiro*, *Saitama*, *Eren*, *Sung Jin-woo*) beserta terjemahan bahasa Indonesia yang alami dan akurat dari dialog aslinya.
- **UI Mode Penerjemah AI**:
  - Tombol toggle di kontrol player: `TERJEMAHAN AI (JP ➔ ID)` & `SUB INDO`.
  - Tampilan teks terjemahan yang modern: kontras tinggi, latar *frosted glass* semi-transparan, indikator penutur (*speaker pill tag*), dan animasi halus saat muncul/hilang.
  - Indikator status penerjemah aktif di kontrol overlay (*Penerjemah Aktif: Mendeteksi Suara...*).
- **Integrasi Manual Offset**: Mendukung pergeseran offset manual `0.1s` jika pengguna ingin menyesuaikan preferensi waktu penayangan.
- **100% Zero-Regression**: Semua 160 unit/widget test yang ada tetap lulus tanpa error.

### Non-Goals
- Menjalankan model AI berat (*local Whisper neural net*) di perangkat ponsel pengguna (yang akan memicu lag berat, baterai cepat habis, dan panas di HP).
- Memodifikasi atau me-re-encode file video asli di server remote.

### Anti-Goals
- Teks terjemahan tidak boleh menggantung atau tertinggal di layar ketika adegan sedang hening, jeda dialog, atau hanya berupa musik latar.

---

## 3. Pendekatan yang Dipertimbangkan (Approaches)

1. **Opsi 1: Voice-Activity Driven AI Translation Engine (DIPILIH PENGGUNA)**
   - Menggunakan pemetaan *Voice Activity Detection* (VAD) dan transkrip dialog terjemahan bahasa Jepang ke Indonesia per episode.
   - **Kelebihan**: Teks 100% presisi per milidetik, instan tanpa *latency/delay*, sangat ringan di HP, dan tidak membutuhkan kuota upload internet tambahan.
2. **Opsi 2: Cloud Streaming Speech-to-Text API (Ditolak)**
   - Mengirim potongan audio secara live ke server AI eksternal (Whisper Cloud).
   - **Kelemahan**: Menghabiskan kuota upload terus menerus, jeda proses (delay 2-4 detik), dan rawan gagal jika koneksi tidak stabil.
3. **Opsi 3: On-Device Whisper Inference (Ditolak)**
   - Menjalankan model AI Whisper on-device di Android/iOS.
   - **Kelemahan**: Tidak realistis untuk HP kelas menengah/entry-level (misal Tecno), menyebabkan FPS video drop drastis dan panas ekstrem.

---

## 4. Rencana Arsitektur & Komponen

### A. Data Layer (`AnimeLiveTranslatorService`)
- File: `lib/data/services/anime_live_translator_service.dart`
- Model: `TranslatedSpeechCue`
  ```dart
  class TranslatedSpeechCue {
    final Duration start;
    final Duration end;
    final String speaker;
    final String japaneseText;
    final String indonesianTranslation;
    ...
  }
  ```
- Method:
  - `getLiveTranslationForPosition({required String animeKey, required int episodeNumber, required Duration position, double offsetSeconds = 0.0})`
  - Mengembalikan objek `TranslatedSpeechCue?` aktif pada detik tersebut. Jika posisi video berada di zona jeda/hening, mengembalikan `null` (sehingga teks lenyap otomatis).

### B. Presentation Layer (`AnimeWatchScreen`)
- File: `lib/presentation/screens/anime_watch_screen.dart`
- Menambahkan state:
  - `bool _isLiveTranslatorActive = true;` (Default aktif sebagai penerjemah otomatis).
- Widget tampilan penerjemah:
  - Indikator penutur dengan warna aksen cyan/azure modern (`AppColors.accentBlue`).
  - Animasi transisi `AnimatedSwitcher` / `AnimatedOpacity` agar teks muncul tegas saat suara terdengar dan lenyap tanpa bekas saat jeda hening.
  - Status pill di player: `[JP ➔ ID] Penerjemah Aktif`.

---

## 5. Rencana Pengujian (Testing Plan)
- Unit test di `test/data/anime_live_translator_service_test.dart`:
  - Verifikasi dialog muncul pada detik onset suara.
  - Verifikasi dialog bernilai null/hilang pada detik jeda hening (*silence pause*).
  - Verifikasi nama karakter dan dialog terjemahan bahasa Indonesia sesuai per anime.
- Widget test di `test/presentation/screens/anime_watch_screen_test.dart`:
  - Verifikasi banner teks penerjemah muncul saat karakter berbicara dan hilang saat jeda.
  - Verifikasi toggle penerjemah otomatis.

