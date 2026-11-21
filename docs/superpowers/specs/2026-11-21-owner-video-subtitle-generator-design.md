# Design Doc: Pembuatan Subtitle Indonesia untuk Video Milik Pemilik (FFmpeg + Faster-Whisper Pipeline)

**Tanggal:** 21 November 2026  
**Status:** Approved  
**Topik:** Fitur Pembuatan Subtitle Indonesia Berkas `.srt` untuk Video Pemilik & Pembersihan Fitur Lama  

---

## 1. Intent & Kebutuhan Pengguna
Pengguna menginstruksikan perubahan arsitektur subtitle secara menyeluruh:
1. **Hapus Penerjemah AI & Sinkronisasi Subtitle**:
   - Menghapus fitur penerjemah AI VAD (`AnimeLiveTranslatorService`, `in_player_live_translator_box`, dsb.).
   - Menghapus bar sinkronisasi manual (`subtitle_sync_bar`, tombol `+0.1s`, `-0.1s`, `reset`, dsb.).
2. **Pembuatan Subtitle Indonesia untuk Video Milik Pemilik**:
   - Khusus untuk video yang sudah terdaftar sebagai milik pemilik aplikasi (`OwnerVideoRepository`).
   - Alur pipeline:
     1. Ekstrak audio dari file video menggunakan `ffmpeg`.
     2. Transkripsi audio menggunakan `faster-whisper` (dengan timestamp per segmen `start`, `end`, dan teks).
     3. Terjemahkan teks hasil transkripsi ke Bahasa Indonesia.
     4. Simpan hasil terjemahan sebagai file `.srt` yang nama dan ID-nya sama dengan video (`<videoId>.srt`).
3. **Penyajian di Pemutar Video (`AnimeWatchScreen`)**:
   - Pemutar **hanya memuat subtitle dari file `.srt` hasil pipeline ini**.
   - **Dilarang keras mengambil subtitle dari internet secara otomatis**.
   - Jika video bukan milik pemilik atau belum memiliki file `.srt`, pemutar tidak menampilkan subtitle (kosong).

---

## 2. Arsitektur Komponen

### A. Pipeline Generator Eksternal (`scripts/generate_owner_subtitles.py`)
Script Python mandiri yang mengorkestrasi pipeline 4 tahap:
1. `extract_audio(video_path, audio_out)`: Mengekstrak stream audio PCM WAV 16kHz mono via `ffmpeg`.
2. `transcribe_with_faster_whisper(audio_path)`: Menggunakan `faster-whisper` untuk mengekstrak segmen ber-timestamp presisi.
3. `translate_segments_to_indonesian(segments)`: Menerjemahkan dialog bahasa Jepang ke bahasa Indonesia alami.
4. `export_to_srt(segments, srt_out_path, video_id)`: Memformat segmen menjadi format standar SubRip `.srt` dengan ID dan penamaan identik dengan video.

### B. Penyimpanan & Parser Subtitle `.srt` (`OwnerSubtitleRepository`)
Berkas: `lib/data/services/owner_subtitle_repository.dart`
- Mengidentifikasi ID unik video milik pemilik:
  `owner_${aniListId}_s${seasonNumber}_ep${episodeNumber}`
- Mengelola bank data berkas `.srt` lokal resmi milik pemilik aplikasi.
- Parser SubRip `.srt`: Mengurai timestamp `HH:MM:SS,mmm --> HH:MM:SS,mmm` menjadi objek `SubtitleCue(start, end, text)`.
- Mengembalikan teks subtitle aktif pada posisi playback tertentu.
- Memastikan pemutar **tidak melakukan pemanggilan HTTP atau scraping internet untuk subtitle**.

### C. Antarmuka Pemutar (`AnimeWatchScreen`)
Berkas: `lib/presentation/screens/anime_watch_screen.dart`
- Menghapus komponen `subtitle_sync_bar` dan state `_subtitleOffsetSeconds`.
- Menghapus komponen `in_player_live_translator_box` dan state `_isLiveTranslatorMode`.
- Menampilkan teks subtitle di `in_player_subtitle_box` hanya jika:
  - Subtitle diaktifkan (`_isSubtitleEnabled == true`).
  - Video merupakan video pemilik resmi (`OwnerVideoRepository.hasVideosForAnime`).
  - Berkas `.srt` hasil pembuatan tersedia dan memiliki segmen pada detik tersebut.
- Jika tidak terdaftar, subtitle tidak dimuat dari internet (tetap kosong).

---

## 3. Rencana Pengujian
1. Unit test untuk `OwnerSubtitleRepository`:
   - Memverifikasi penguraian berkas `.srt` (SubRip format dengan timestamp koma `,`).
   - Memverifikasi pengambilan subtitle untuk video milik pemilik.
   - Memverifikasi penolakan pemuatan subtitle dari internet untuk video yang tidak terdaftar.
2. Widget test untuk `AnimeWatchScreen`:
   - Memverifikasi tampilan subtitle dari berkas `.srt` video pemilik.
   - Memverifikasi tidak adanya elemen `subtitle_sync_bar` dan `in_player_live_translator_box`.
   - Memverifikasi toggle `btn_toggle_subtitles` menyalakan dan mematikan subtitle lokal.
3. Seluruh test suite (160+ tests) dan `flutter analyze` harus bebas error (0 issues).

