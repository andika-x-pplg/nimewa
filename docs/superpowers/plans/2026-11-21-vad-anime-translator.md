# Penerjemah Otomatis Bahasa Jepang ke Indonesia Berbasis VAD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun fitur Penerjemah Teks Otomatis (Live AI Translator) pada pemutar video anime yang menampilkan teks terjemahan bahasa Indonesia sinkron persis saat karakter berbicara dan lenyap saat jeda hening.

**Architecture:** Model `TranslatedSpeechCue` dan service `AnimeLiveTranslatorService` menyediakan pemetaan voice activity detection (onset, offset, penutur, dan teks terjemahan bahasa Indonesia). UI `AnimeWatchScreen` menampilkan terjemahan dinamis dengan tag penutur dan mode toggle.

**Tech Stack:** Flutter 3.x, Dart 3.x, video_player.

**Spec:** `docs/superpowers/specs/2026-11-21-vad-anime-translator-design.md`

## Global Constraints
- Jangan mengubah file video asli maupun URL stream MP4.
- Jangan membebani perangkat dengan inferensi model lokal berat.
- Semua 160 tes yang ada saat ini harus tetap lolos 100% tanpa warning pada `flutter analyze`.

---

### Task 1: Bangun Service `AnimeLiveTranslatorService` dan Model `TranslatedSpeechCue`

**Files:**
- Create: `lib/data/services/anime_live_translator_service.dart`

- [x] Definisikan `TranslatedSpeechCue` dengan properti: `start`, `end`, `speaker`, `japaneseUtterance`, `indonesianTranslation`.
- [x] Buat metode `getLiveTranslationForPosition` dengan toleransi VAD presisi milidetik.
- [x] Sediakan bank data terjemahan berwaktu presisi (onset dan offset bicara karakter) untuk anime populer (*Demon Slayer*, *One Punch Man*, *Attack on Titan*, *Solo Leveling*, *Tokyo Ghoul*, *Tokyo Revengers*).
- [x] Pastikan jika video berada pada rentang jeda/hening, metode mengembalikan `null` agar teks terjemahan menghilang.

---

### Task 2: Buat Unit Test untuk `AnimeLiveTranslatorService`

**Files:**
- Create: `test/data/anime_live_translator_service_test.dart`

- [x] Tulis unit test untuk memverifikasi teks terjemahan muncul tepat pada detik `start` hingga `end`.
- [x] Tulis unit test untuk memverifikasi teks terjemahan bernilai `null` saat berada pada jeda hening antardialog.
- [x] Tulis unit test untuk memverifikasi nama penutur (*speaker*) dan teks terjemahan bahasa Indonesia sesuai per anime.
- [x] Jalankan `flutter test test/data/anime_live_translator_service_test.dart` dan pastikan lolos.

---

### Task 3: Integrasikan Penerjemah AI ke UI `AnimeWatchScreen`

**Files:**
- Modify: `lib/presentation/screens/anime_watch_screen.dart`

- [x] Tambahkan toggle mode penerjemah: `_isLiveTranslatorMode = true;`
- [x] Buat widget tampilan teks penerjemah AI (`in_player_live_translator_box`) dengan pill penutur/speaker, teks terjemahan kontras tinggi, dan animasi transisi halus.
- [x] Tambahkan indikator status di bar player: `TERJEMAHAN AI (JP ➔ ID)`.
- [x] Hubungkan manual offset repository agar penyesuaian waktu tetap berlaku pada mode penerjemah.

---

### Task 4: Tambahkan Pengujian Widget dan Verifikasi Regresi Menyeluruh

**Files:**
- Modify: `test/presentation/screens/anime_watch_screen_test.dart`

- [x] Tambahkan widget test untuk memverifikasi box terjemahan AI muncul saat karakter berbicara dan hilang saat jeda hening.
- [x] Tambahkan widget test untuk toggle mode penerjemah AI.
- [x] Jalankan `flutter analyze` dan pastikan 0 error/warning.
- [x] Jalankan `flutter test` untuk seluruh rangkaian tes proyek.

