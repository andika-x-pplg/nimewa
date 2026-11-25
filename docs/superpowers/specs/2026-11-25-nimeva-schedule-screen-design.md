# Spesifikasi Desain: Halaman Jadwal Tayang Anime (Nimeva)

**Tanggal:** 2026-11-25  
**Status:** Siap Direview Pengguna (Hasil Builder Check Diterapkan)  
**Target Lokasi:** Tab ke-3 (`Jadwal`) pada `HomeScreen`

---

## 1. Tujuan & Latar Belakang

Mengaktifkan tab **Jadwal** (`CustomBottomNavBar` indeks `2`) yang saat ini masih berupa placeholder menjadi halaman jadwal tayang anime real-time berbasis API AniList (`https://graphql.anilist.co`). Pengguna dapat memantau episode terbaru yang sudah rilis maupun yang akan tayang sepanjang pekan berjalan (Minggu sampai Sabtu) sesuai tanggal dan jam lokal perangkat, lengkap dengan poster, judul, nomor episode, waktu rilis, status keterlambatan/libur, serta pengingat episode.

---

## 2. Ruang Lingkup (Goals, Non-Goals, Anti-Goals)

### Goals
- **Rentang Pekan Bergulir (Minggu ke Sabtu):** Menampilkan 7 hari berurutan dari kiri ke kanan dimulai dari hari **Minggu** hingga **Sabtu** (contoh: `Min 22`, `Sen 23`, `Sel 24`, `Rab 25`, `Kam 26`, `Jum 27`, `Sab 28` pada bulan November 2026). Ketika memasuki hari Minggu berikutnya (tanggal 29), seluruh bar pekan otomatis berganti ke pekan baru (`Min 29` sampai `Sab 5`) sehingga pekan lama hilang.
- **Semua Hari Dapat Diakses:** Hari yang sudah lewat, hari ini, maupun hari mendatang (`Kam`, `Jum`, `Sab`) tetap tampil dan dapat dipilih untuk melihat anime serta jam rilisnya masing-masing.
- **Data Real-Time via AniList GraphQL API:** Mengambil `airingSchedules` sesuai rentang waktu pekan lokal dengan *auto-pagination* agar seluruh hari dalam 1 minggu terisi penuh (tidak terpotong batas 50 item per halaman).
- **Status Waktu Rilis Akurat:** Menampilkan jam rilis lokal (`HH:mm`, misalnya `06:28`), status sudah rilis (misalnya jika rilis `06:28` dilihat pukul `07:00`, tertulis `"Sudah rilis · 06:28"` atau `"Baru rilis · 06:28"` jika kurang dari 60 menit), serta hitung mundur untuk jadwal hari/jam mendatang (`"Rilis 19:30 · Dalam 1j 30m"` atau `"Dalam 1h 9j"`).
- **Penanda Tertunda / Libur Real-Time:** Membandingkan jadwal pekan lalu (`weekStart - 7 hari`) dengan pekan berjalan (`weekStart .. weekEnd`) dari AniList untuk mendeteksi judul `RELEASING` yang minggu ini libur/melompat jadwal (karena `status: HIATUS` di AniList tidak aktif untuk jeda mingguan). Anime yang libur ditempatkan langsung di slot hari dan jam tayang normalnya pada timeline dengan indikator amber `#FFB800` dan keterangan `"Libur minggu ini · Tayang lagi <tgl>"`.
- **Konsistensi Visual Nimeva & Antislop (Mode DURING):** Menggunakan palet Monochrome OLED (`#000000` latar, `#121212` kartu, `#1C1C1E` elevated, `#26262A` border, `#0066FF` aksen utama, `#FFB800` penanda jeda/rating) dan `AppTypography`.
- **Interaksi Nyata:** Ketuk kartu (atau ikon pada episode yang sudah rilis) selalu membuka `AnimeDetailScreen` untuk melihat detail, memutar episode bila tersedia di Nimeva, atau membuka tautan resmi. Tombol lonceng hanya muncul pada episode mendatang dan episode tertunda untuk mengatur pengingat lokal (*in-memory state* dengan umpan balik `SnackBar`), sedangkan tombol lonceng di header menyaring daftar ke mode *"Hanya Pengingat"*.

### Non-Goals
- Push notification OS latar belakang (*background alarm/FCM*), karena tidak ada infrastruktur backend notifikasi di proyek saat ini.
- Memfilter jadwal hanya pada judul yang memiliki berkas MP4 di `OwnerVideoRepository` (diputuskan menampilkan seluruh jadwal AniList agar setiap tanggal terisi penuh).
- Membuat jadwal sintetis/palsu dari anime yang sudah tamat saat API gagal pertama kali (diganti Error State jujur dengan tombol `"Coba Lagi"`).

### Anti-Goals
- Jangan memakai warna ungu dari gambar referensi maupun pola generik AI (gradien biru-ungu, glow berlebihan, karakter em-dash `—`, atau tombol dekoratif tanpa fungsi).
- Jangan menayangkan konten dewasa (`isAdult: true`).
- Jangan melakukan *hardcode* zona waktu (misalnya selalu GMT+7); gunakan `DateTime.now()` agar mengikuti zona waktu perangkat.

---

## 3. Pendekatan Arsitektur yang Dipilih

### Opsi yang Dipertimbangkan
1. **Pendekatan A: Full-Week Auto-Pagination + Cache Pekanan (Dipilih)**  
   Mengambil seluruh `airingSchedules` dari Minggu `00:00:00` hingga Sabtu `23:59:59` waktu lokal sekaligus dengan pagination berurutan hingga `hasNextPage == false`, ditambah query anime berstatus `HIATUS` musim aktif, lalu menyimpannya di cache per kunci pekan. Pindah antar hari di tab Jadwal langsung instan (0 ms) dan mengurangi risiko batas rate-limit AniList.
2. **Pendekatan B: Lazy Per-Day Fetch (Ditolak)**  
   Hanya mengambil API per tanggal yang diklik. Menimbulkan jeda loading berulang setiap pengguna mengetuk tab hari dan boros kuota API.

---

## 4. Desain Data & Layanan

### 4.1 Model Baru (`lib/data/models/schedule_entry.dart`)
- `enum ScheduleReleaseStatus { released, upcoming, delayedOrHiatus }`
- `class ScheduleEntry`:
  - `final int scheduleId;`
  - `final int mediaId;`
  - `final String title;`
  - `final String japaneseTitle;`
  - `final String posterUrl;`
  - `final String? bannerUrl;`
  - `final double rating;`
  - `final List<String> genres;`
  - `final String synopsis;`
  - `final String format;` (`TV`, `ONA`, `MOVIE`, `OVA`, dll.)
  - `final int episodeNumber;`
  - `final DateTime airingAt;` (waktu tayang di pekan ini, atau waktu slot normal `prevAiringAt + 7 hari` untuk item yang libur minggu ini, dikonversi ke lokal dengan `DateTime.fromMillisecondsSinceEpoch(..., isUtc: true).toLocal()`)
  - `final bool isHiatusOrDelayed;`
  - `final DateTime? nextAiringAt;` (waktu tayang episode berikutnya jika libur minggu ini, misalnya `5 Des`)
  - `final String? delayNote;` (misalnya `"Libur minggu ini · Tayang lagi 5 Des"`)
  - `final bool hasVideoAvailable;` (dicek terhadap `AnimeStreamResolver.hasCompleteEpisodes`)
  - Metode bantu:
    - `ScheduleReleaseStatus statusAt(DateTime now)`
    - `String formattedTime()` (`HH:mm`)
    - `String formatStatusText(DateTime now)`
    - `AnimeItem toAnimeItem()` untuk navigasi ke `AnimeDetailScreen`
- `class WeeklyScheduleResult`:
  - `final DateTime weekStart;` (Minggu `00:00:00` lokal)
  - `final DateTime weekEnd;` (Sabtu `23:59:59` lokal)
  - `final Map<String, List<ScheduleEntry>> entriesByDateKey;` (kunci `YYYY-MM-DD`, terurut kronologis berdasarkan `airingAt`, mencakup jadwal tayang maupun slot item yang libur minggu ini)
  - `final bool isStaleCache;` (`true` jika menampilkan ulang cache yang sudah kedaluwarsa saat offline)

### 4.2 Perhitungan Pekan & Waktu (`ScheduleDateHelper`)
- Menggunakan fungsi statis murni yang menerima `DateTime referenceNow` (dapat di-inject untuk unit test deterministik):
  - `weekStartSunday(DateTime now)`: menghitung Minggu pada pekan yang sama: `final daysFromSunday = now.weekday % 7;` (`DateTime.sunday == 7` -> `0`, `monday == 1` -> `1`, ..., `saturday == 6` -> `6`), lalu `DateTime(now.year, now.month, now.day - daysFromSunday)`.
  - `weekDays(DateTime now)`: mengembalikan daftar 7 `DateTime` dari Minggu s.d. Sabtu.
  - `dateKey(DateTime dt)`: `'${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'`.
  - Label hari Indonesia singkat: `Min`, `Sen`, `Sel`, `Rab`, `Kam`, `Jum`, `Sab`.
  - Label bulan Indonesia / kapital sesuai header: `JANUARI` .. `DESEMBER`.

### 4.3 Ekstensi `AniListApiClient` (`lib/data/services/anilist_api_client.dart`)
- Menambah metode `Future<WeeklyScheduleResult> fetchWeeklySchedule({DateTime? now, bool forceRefresh = false})`:
  1. Hitung rentang pekan berjalan (`weekStart` Minggu `00:00:00` lokal s.d. `weekEnd` Sabtu `23:59:59` lokal) dan pekan sebelumnya (`prevWeekStart = weekStart - 7 hari` s.d. `weekStart`) dalam epoch detik UTC.
  2. Loop GraphQL `Page(page: p, perPage: 50)` query `airingSchedules(airingAt_greater: $start, airingAt_lesser: $end, sort: [TIME])` hingga `pageInfo.hasNextPage == false` (batas aman maksimal 8 halaman) untuk pekan berjalan, dan ambil juga jadwal pekan sebelumnya (beserta field `media { id status nextAiringEpisode { episode airingAt } }`).
  3. Filter keluar item dengan `media.isAdult == true` atau `media.title` kosong.
  4. **Deteksi Libur / Tertunda Pekan Ini:** Setiap `media` pada pekan sebelumnya yang berstatus `RELEASING`, tidak muncul di pekan berjalan, dan memiliki `nextAiringEpisode` berjarak `>= 10 hari` dari jadwal pekan lalunya dimasukkan ke slot `prevAiringAt + 7 hari` pada `entriesByDateKey` dengan `isHiatusOrDelayed = true`, `episodeNumber = prevEpisode + 1`, `nextAiringAt`, serta `delayNote = "Libur minggu ini · Tayang lagi <d> <Bulan>"`.
  5. Cek kesediaan video di Nimeva untuk setiap item melalui `AnimeStreamResolver.hasCompleteEpisodes(mediaId, title)`.
  6. Simpan cache in-memory per `weekKey` (`YYYY-MM-DD` dari `weekStart`) dengan TTL 10 menit.
  7. **Penanganan Offline / Error:** Jika permintaan API gagal dan cache untuk `weekKey` belum pernah ada, metode **melempar exception** agar `ScheduleScreen` menampilkan Error State yang jujur dengan tombol `"Coba Lagi"`. Jika cache untuk `weekKey` sudah ada (meski TTL lewat), kembalikan cache tersebut dengan `isStaleCache: true` agar UI tetap tampil disertai banner info offline. *(Keputusan uji `home_screen_test.dart`: pastikan pengujian widget `HomeScreen` tidak menggantung pada kegagalan HTTP real karena Error State langsung selesai merender.)*

---

## 5. Desain UI & Kepatuhan Antislop + Responsivitas

### 5.1 Dial Antislop
- **ENERGY:** `2` (Tegas dan terstruktur, judul tebal + kartu kontras tinggi).
- **RHYTHM:** `2` (Header ringkas -> bar 7 hari -> timeline kronologis dengan variasi badge status).
- **MOTION:** `1` (Transisi state halus pada pilihan hari & toggle pengingat tanpa animasi mengambang/berlebihan).

### 5.2 Hirarki Halaman `ScheduleScreen` (`lib/presentation/screens/schedule_screen.dart`)
1. **Header:**
   - Teks pengantar kecil (`AppTypography.labelMedium`, `AppColors.textSecondary`): `"Jangan lewatkan episode terbaru."`
   - Judul utama (`AppTypography.headlineMedium`): `"Jadwal Rilis"`
   - Tombol ikon di kanan (`44x44` min tap target): Toggle filter **Pengingat** (`Icons.notifications_active_rounded` / `Icons.notifications_none_rounded`) dengan titik aksen `#0066FF` saat ada pengingat aktif.
2. **Info Bulan & Zona Waktu + Bar 7 Hari (`ScheduleWeekBar`):**
   - Baris info: kiri bulan & tahun (misalnya `"NOVEMBER 2026"`), kanan zona waktu lokal dinamis (misalnya `"Waktu Lokal · GMT+8"`).
   - 7 kolom hari sejajar dari `Min` sampai `Sab` (`Expanded` di mobile agar pas selebar layar tanpa *horizontal overflow*; di tablet/desktop tetap terpusat dengan `maxWidth`).
   - Setiap sel hari minimal tinggi `64dp` (melebihi syarat `44x44`), menampilkan nama hari singkat, tanggal angka, dan titik indikator kecil untuk hari ini (*today*) atau hari yang memiliki pengingat. Hari aktif diberi warna `#0066FF` (`AppColors.accentBlue`), hari lain `#121212` dengan border `#26262A`.
3. **Section Header Daftar Harian:**
   - Judul dinamis di kiri: `"Tayang Hari Ini"` (jika hari ini dipilih), `"Sudah Tayang · Min, 22 Nov"` (jika tanggal lampau), atau `"Akan Tayang · Kam, 26 Nov"` (jika tanggal mendatang), diikuti chip/teks jumlah episode di kanan (`"12 episode"`).
   - Bila `isStaleCache == true`, tampilkan banner ringkas bahwa data berasal dari cache terakhir beserta tombol segarkan. Bila filter pengingat aktif, tampilkan chip info jumlah pengingat aktif.
4. **Timeline Episode (`ScheduleTimelineCard`):**
   - **Layout Responsif (`LayoutBuilder`):**
     - `maxWidth <= 600`: daftar 1 kolom vertikal dengan *timeline* di sisi kiri.
     - `maxWidth > 600`: konten dibatasi `ConstrainedBox(maxWidth: 960)` di tengah, dan kartu jadwal ditampilkan dalam 2 kolom grid agar tidak melebar berlebihan di tablet/desktop.
   - **Struktur Tiap Item:**
     - Kolom waktu kiri (`width: 52`): jam lokal `HH:mm` (`AppTypography.labelLarge`) + titik status (`#0066FF` jika sudah tayang hari ini / baru rilis, `#71717A` jika akan tayang, `#FFB800` jika libur/tertunda) + garis penghubung vertikal tipis `#26262A`.
     - Kartu utama (`#121212`, border `1px` `#26262A`, radius `12dp`, padding `12dp`, mengetuk kartu membuka `AnimeDetailScreen`):
       - Poster portrait (`width: 68, height: 96`, radius `8dp`, `Image.network` + `AnimeImagePlaceholder` fallback).
       - Kolom info tengah (`Expanded`):
         - Judul anime (`AppTypography.titleMedium`, `maxLines: 2`, ellipsis).
         - Sub-judul episode (`"Episode 8"` + format bila bukan TV, plus badge `"Tersedia"` `#0066FF` bila `hasVideoAvailable == true`).
         - Keterangan waktu rilis / status (`"Sudah rilis · 06:28"`, `"Baru rilis · 06:28"`, `"Rilis 19:30 · Dalam 1j 30m"`, atau `"Libur minggu ini · Tayang lagi <tgl>"` dalam warna `#FFB800`).
       - Tombol aksi kanan (`44x44` min tap target, Keputusan Builder):
         - Untuk episode mendatang (`upcoming`) atau libur (`delayedOrHiatus`): ikon lonceng toggle pengingat lokal.
         - Untuk episode sudah rilis (`released`): ikon play `#0066FF` (jika `hasVideoAvailable == true`) atau chevron `Icons.chevron_right_rounded` (jika belum ada video lokal); keduanya membuka `AnimeDetailScreen` seperti pola `"Tonton Sekarang"` di `SpotlightCarousel`.
5. **Tiga State UI Wajib (R-27):**
   - **Loading:** Indikator loading + pesan singkat `"Memuat jadwal anime..."`.
   - **Error:** Pesan kesalahan yang jelas + tombol `"Coba Lagi"`.
   - **Empty:** Ikon kalender + pesan jujur saat tidak ada jadwal tayang (atau tidak ada episode di filter pengingat) pada hari tersebut, disertai tombol kembali ke hari ini / reset filter.
6. **Padding Bawah:** Memberi ruang bawah pada scroll view + `SafeArea` agar `CustomBottomNavBar` tidak pernah menutupi kartu terbawah.

---

## 6. Yang Diserahkan ke Implementer / Rencana Kerja
- Pemilihan nama helper internal, detail animasi transisi chip hari (`150ms`), serta rincian struktur unit test (dengan `MockClient`/override untuk `AniListApiClient` dan clock `nowProvider`) dan widget test (menguji perpindahan hari Minggu-Sabtu, pergantian pekan saat hari Minggu baru, status sudah rilis vs akan tayang vs libur/tertunda, toggle pengingat, responsivitas narrow/wide, dan error/empty/loading state).

