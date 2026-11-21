# Pembuatan Subtitle Indonesia untuk Video Milik Pemilik Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun fitur pembuatan subtitle Indonesia berkas `.srt` untuk video milik pemilik aplikasi (alur: ekstraksi audio ffmpeg, transkripsi faster-whisper, terjemahan ke Indonesia, penyimpanan `.srt` sesuai ID/nama video), memastikan pemutar hanya memuat subtitle dari berkas hasil ini tanpa mengambil subtitle dari internet, serta menghapus fitur penerjemah AI VAD dan bar sinkronisasi manual lama.

**Architecture:** Script Python `scripts/generate_owner_subtitles.py` mengeksekusi pipeline ekstraksi audio, transkripsi faster-whisper, penerjemahan, dan ekspor `.srt`. Repositori `OwnerSubtitleRepository` di Flutter memuat dan mem-parsing berkas `.srt` video pemilik. Pemutar `AnimeWatchScreen` hanya menampilkan subtitle dari repositori ini dan membersihkan UI sinkronisasi & penerjemah AI.

**Tech Stack:** Flutter 3.x, Dart 3.x, Python 3.10, FFmpeg, faster-whisper, SubRip (.srt).

**Spec:** `docs/superpowers/specs/2026-11-21-owner-video-subtitle-generator-design.md`

---

### Task 1: Hapus Fitur Penerjemah AI VAD dan Subtitle Sync Bar Lama
- [x] Hapus file service `lib/data/services/anime_live_translator_service.dart` dan unit test `test/data/anime_live_translator_service_test.dart`.
- [x] Bersihkan `AnimeWatchScreen` dari elemen `_isLiveTranslatorMode`, `_currentLiveTranslation`, `_buildLiveTranslatorBox`, `btn_toggle_live_translator`, `_buildSubtitleSyncBar()`, `_adjustSubtitleOffset()`, `_resetSubtitleOffset()`, dan `_subtitleOffsetSeconds`.
- [x] Perbarui `test/presentation/screens/anime_watch_screen_test.dart` untuk menghapus pengujian sinkronisasi manual dan AI translator lama.

---

### Task 2: Buat Pipeline Script Python `scripts/generate_owner_subtitles.py`
- [x] Buat script Python yang mengimplementasikan 4 langkah:
  1. Ekstraksi audio via `ffmpeg`.
  2. Transkripsi dengan timestamp per segmen via `faster-whisper`.
  3. Penerjemahan dialog ke Bahasa Indonesia.
  4. Penyimpanan ke format SubRip `.srt` dengan penamaan file dan ID yang sama dengan video pemilik (`<videoId>.srt`).
- [x] Tambahkan generator batch otomatis untuk video-video milik pemilik terdaftar di `OwnerVideoRepository`.

---

### Task 3: Bangun Service & Repositori `OwnerSubtitleRepository`
- [x] Buat model / cue subtitle dan parser berkas `.srt` (SubRip format: index, timestamp `HH:MM:SS,mmm --> HH:MM:SS,mmm`, teks Indonesia).
- [x] Implementasikan `OwnerSubtitleRepository` di `lib/data/services/owner_subtitle_repository.dart`:
  - Menyimpan dan memuat berkas `.srt` resmi milik pemilik aplikasi.
  - Memetakan `<videoId>.srt` berdasarkan `aniListId`, `seasonNumber`, `episodeNumber`.
  - Memastikan hanya video milik pemilik yang dimuat subtitlenya.
  - Memastikan tidak ada pengambilan subtitle otomatis dari internet.
- [x] Buat unit test di `test/data/owner_subtitle_repository_test.dart`.

---

### Task 4: Integrasikan `OwnerSubtitleRepository` ke `AnimeWatchScreen` & Verifikasi Menyeluruh
- [x] Hubungkan `AnimeWatchScreen` ke `OwnerSubtitleRepository`.
- [x] Pastikan pemutar hanya menampilkan subtitle dari berkas `.srt` video pemilik jika tersedia, dan tidak mengambil dari internet.
- [x] Jalankan `flutter analyze` dan pastikan 0 error/warning.
- [x] Jalankan `flutter test` untuk memastikan semua tes proyek lolos 100%.

