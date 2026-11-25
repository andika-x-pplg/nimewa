# Spesifikasi Desain: Halaman My List & Sinkronisasi Daftar Anime (Nimeva)

**Tanggal:** 2026-11-25  
**Status:** Siap Direview Pengguna (Hasil Builder Check Diterapkan)  
**Target Lokasi:** Tab ke-4 (`My list`) pada `HomeScreen`, tombol `+` di `SpotlightCarousel`, tombol `"Simpan Anime"` di `AnimeDetailScreen`, dan pelacakan progres di `AnimeWatchScreen`

---

## 1. Tujuan & Latar Belakang

Mengaktifkan tab **My list** (`CustomBottomNavBar` indeks `3`) yang saat ini masih berupa placeholder menjadi halaman manajemen daftar anime pribadi pengguna. Pengguna dapat menyimpan anime dari Beranda (`+`) maupun Detail Anime (`"Simpan Anime"`), mengelompokkannya ke dalam 3 kategori fungsional (**Watching**, **Saved**, **Completed**), melihat progres episode serta persentase selesai dan sisa persentase, memantau progres otomatis saat menonton di `AnimeWatchScreen`, mengubah status/progres secara manual, serta menghapus anime dari daftar.

---

## 2. Ruang Lingkup (Goals, Non-Goals, Anti-Goals)

### Goals
- **Integrasi Simpan Anime:**
  - Di **Beranda** (`HomeScreen` + `SpotlightCarousel`): tombol `+` menyimpan anime ke `Saved` (atau melepas/toggle dengan konfirmasi `SnackBar`, dan ikon berubah menjadi centang `Icons.check_rounded` saat anime sudah ada di My List).
  - Di **Detail Anime** (`AnimeDetailScreen`): teks `"Daftar Tonton"` diganti menjadi **`"Simpan Anime"`** (berubah menjadi **`"Tersimpan"`** dengan ikon bookmark aktif `#0066FF` saat tersimpan di My List, serta tersinkronisasi langsung dengan `MyListRepository`).
- **3 Tab Fungsional di Halaman My List:**
  - **Watching:** Anime yang sedang ditonton (`0 < watchedEpisode < totalEpisodes` atau status manual `watching`).
  - **Saved:** Anime yang disimpan dan belum mulai ditonton (`watchedEpisode == 0`, status `saved`).
  - **Completed:** Anime yang selesai ditonton (`watchedEpisode >= totalEpisodes` atau status manual `completed`, `100%`).
  - Masing-masing tab menampilkan jumlah item dinamis (contoh: `Watching · 3`, `Saved · 5`, `Completed · 2`, atau tanpa angka jika `0` / dengan `0` yang jelas).
- **Progres Persentase & Sisa Menuju Tamat:**
  - Setiap kartu menampilkan progres episode (`"X dari Y episode"`), bar progres `#0066FF`, persentase selesai, dan sisa persentase (`"67% selesai · Sisa 33%"`).
  - **Anime dengan Video Tersedia (`hasVideoAvailable == true`):** Ketika episode diputar di `AnimeWatchScreen` (termasuk saat berpindah ke episode 1, 2, 3, dst.), `MyListRepository.recordWatchProgress` otomatis mencatat episode tertinggi/terakhir yang ditonton, memperbarui persentase, memindahkan item dari `Saved` ke `Watching`, dan otomatis memindahkannya ke `Completed` (`100%`) ketika mencapai episode terakhir (`watchedEpisode >= totalEpisodes`).
  - **Anime Tanpa Video di Aplikasi (`hasVideoAvailable == false`):** Tetap dapat disimpan ke **My List** (masuk ke `Saved` dengan `0%`). Karena pemutaran lewat platform resmi eksternal tidak dapat dilacak otomatis, progres otomatisnya tetap `0%` dan kartu menampilkan keterangan `"Platform resmi · Progres 0%"` (serta mengetuk kartu membuka `AnimeDetailScreen` agar pengguna bisa memakai tombol platform resmi). Pengguna tetap dapat memperbarui status/progres secara manual atau menghapus item.
- **Ubah Status, Atur Progres Manual & Hapus Item:**
  - Setiap kartu memiliki tombol aksi menu (`⋯`, minimal `44x44` dp) dengan pilihan: **Pindah Status** (`Watching` / `Saved` / `Completed`), **Atur Episode Terakhir** (dialog input/stepper episode `0..totalEpisodes`), dan **Hapus dari My List** (disertai `SnackBar` konfirmasi + opsi `"Urungkan"`).
- **Penyimpanan Lokal Permanen:**
  - `MyListRepository` (`ChangeNotifier`) menyimpan dan memuat data dari file JSON lokal (`dart:io`) tanpa menambah dependensi eksternal baru di `pubspec.yaml`, sehingga data tidak hilang saat aplikasi ditutup atau pindah tab.
- **Konsistensi Visual Nimeva & Antislop (Mode DURING):**
  - Menggunakan palet OLED (`#000000` latar, `#121212` kartu, `#1C1C1E` elevated, `#26262A` border, `#0066FF` aksen biru, `#FFFFFF`/`#A1A1AA`/`#71717A` teks) dan `AppTypography`, nol em-dash (`—`), tanpa warna ungu dari gambar referensi.

### Non-Goals
- Sinkronisasi akun ke server eksternal / cloud (seperti AniList OAuth sync).
- Menambah dependensi native baru (`shared_preferences` / `sqflite`) ke `pubspec.yaml`.

### Anti-Goals
- Jangan membiarkan tombol `+` di Beranda atau `"Simpan Anime"` di Detail hanya mengubah state lokal sementara yang tidak masuk ke tab **My list**.
- Jangan memakai teks `"Daftar Tonton"` pada tombol simpan di `AnimeDetailScreen`.
- Jangan menampilkan persentase salah (`> 100%`, `NaN`, atau pembagian dengan nol jika `totalEpisodes <= 0`).

---

## 3. Desain Data & Layanan

### 3.1 Model `MyListEntry` (`lib/data/models/my_list_entry.dart`)
- `enum MyListStatus { watching, saved, completed }`
- `class MyListEntry`:
  - `final String animeId;` (ID kanonis dari `AnimeItem.id` / `aniListId.toString()`)
  - `final int aniListId;`
  - `final String title;`
  - `final String japaneseTitle;`
  - `final String posterUrl;`
  - `final String backdropUrl;`
  - `final double rating;`
  - `final int releaseYear;`
  - `final List<String> genres;`
  - `final String description;`
  - `final int totalEpisodes;` (minimal `1` untuk movie/unknown fallback saat menghitung persen, atau jika `0` dari metadata belum rilis dianggap `0%` sampai diketahui)
  - `final int watchedEpisode;` (rentang `0..totalEpisodes` saat `totalEpisodes > 0`)
  - `final String? currentEpisodeTitle;` (misalnya `"Ep 3 · Judul"` atau `"Episode 3"`)
  - `final MyListStatus status;`
  - `final bool hasVideoAvailable;`
  - `final DateTime updatedAt;`
- **Perhitungan Persentase & Sisa (Properti murni):**
  - `int get completedPercent`:
    - Jika `status == MyListStatus.completed`: `100`
    - Jika `totalEpisodes <= 0` atau `watchedEpisode <= 0`: `0`
    - Selain itu: `((watchedEpisode / totalEpisodes) * 100).round().clamp(0, 100)`
  - `int get remainingPercent => (100 - completedPercent).clamp(0, 100);`
  - `double get progressFraction => completedPercent / 100.0;`
  - `String get progressSummaryText`:
    - Jika `!hasVideoAvailable && watchedEpisode == 0 && status == MyListStatus.saved`: `'Platform resmi · Progres 0%'`
    - Jika `totalEpisodes > 0`: `'$watchedEpisode dari $totalEpisodes episode'`
    - Selain itu: `'Episode $watchedEpisode'`
  - `String get percentSummaryText`: `'$completedPercent% selesai · Sisa $remainingPercent%'`
  - `AnimeItem toAnimeItem()` untuk navigasi ke `AnimeDetailScreen`.
  - `Map<String, dynamic> toJson()` & `factory MyListEntry.fromJson(Map<String, dynamic> json)`.

### 3.2 `MyListRepository` (`lib/data/services/my_list_repository.dart`)
- `class MyListRepository extends ChangeNotifier`
- Mendukung `static final MyListRepository instance = MyListRepository._internal();` serta konstruktor publik `MyListRepository({File? storageFile, bool disablePersistence = false})` untuk pengujian unit/widget terisolasi.
- **Lokasi File Penyimpanan Default (`dart:io`):**
  - Mencoba menulis di direktori aplikasi yang dapat ditulis tanpa plugin tambahan (misal di Android memeriksa `Directory('/data/user/0/com.example.nimeva/files')` / `Platform.environment['HOME']` / fallback aman `Directory.systemTemp.path` dengan nama berkas `nimeva_my_list.json`). Seluruh operasi I/O dibungkus `try/catch` agar tidak pernah melempar crash ke UI bila sandbox membatasi akses file.
- **Normalisasi ID Kanonis & Otoritas Data (`AnimeStreamResolver`):**
  - Karena ID anime berbeda-beda antar sumber (`'demon-slayer'` di mock, `'101922'` di AniList, `'41370'` di beberapa entri), `MyListRepository` menormalkan kunci kanonis menggunakan `AnimeStreamResolver.detectAnimeKey(animeId, title)` sehingga item yang sama dari Beranda, Explore, Jadwal, dan Detail tidak pernah ganda.
  - Kebenaran `hasVideoAvailable` dihitung secara konsisten lewat `AnimeStreamResolver.hasCompleteEpisodes(animeId, title)`.
  - Bila `totalEpisodes` dari metadata belum diketahui atau `0` (misal anime `!hasVideoAvailable`), parser mencoba mengekstrak jumlah episode dari `episodeInfo` (seperti `'SUB · 24 EPS'` -> `24`), dan dialog `"Atur Episode Terakhir"` tetap mengizinkan input/stepper bebas (`>= 0`) tanpa memblokir pengguna.
- **Metode Utama:**
  - `Future<void> init()` (memuat JSON awal sekali secara idempoten).
  - `List<MyListEntry> get allEntries` (diurutkan berdasarkan `updatedAt` terbaru).
  - `List<MyListEntry> entriesByStatus(MyListStatus status)`
  - `int countByStatus(MyListStatus status)`
  - `bool contains(String animeId, {int aniListId = 0, String title = ''})` (mencocokkan berdasarkan kunci kanonis `detectAnimeKey`, `animeId`, maupun `aniListId > 0`).
  - `MyListEntry? findEntry(String animeId, {int aniListId = 0, String title = ''})`
  - `Future<bool> toggleSaveAnime(AnimeItem item, {int? totalEpisodes})` — mengembalikan `true` jika baru disimpan (`Saved`), `false` jika dihapus.
  - `Future<bool> toggleSaveFromDetail(AnimeDetail detail)` — menyimpan `AnimeDetail` ke `Saved` jika belum ada (mengembalikan `true`), atau menghapus jika sudah tersimpan (mengembalikan `false`) agar konsisten dengan aksi `"Urungkan"`.
  - `Future<void> recordWatchProgress({required AnimeDetail detail, required int episodeNumber, String? episodeTitle})` — dipanggil oleh `AnimeWatchScreen` saat video mulai diputar/ganti episode:
    - Hanya menaikkan progres otomatis bila `AnimeStreamResolver.hasCompleteEpisodes(detail.id, detail.title) && detail.hasVideoAvailable`.
    - Menambah/memperbarui entri: `watchedEpisode = max(existing.watchedEpisode, episodeNumber)`. Jika `totalEps > 0 && watchedEpisode >= totalEps`, status otomatis menjadi `MyListStatus.completed`; selain itu menjadi `MyListStatus.watching`.
  - `Future<void> updateStatus(String canonicalKeyOrId, MyListStatus newStatus)` (jika pindah ke `completed` & `totalEpisodes > 0`, set `watchedEpisode = totalEpisodes`; jika pindah ke `saved`, set `watchedEpisode = 0`).
  - `Future<void> updateEpisodeProgress(String canonicalKeyOrId, int episodeNumber)` (memperbarui episode manual, otomatis menyesuaikan `saved`/`watching`/`completed`, dan menaikkan `totalEpisodes` bila input melebihi `0`).
  - `Future<MyListEntry?> removeEntry(String canonicalKeyOrId)` & `Future<void> restoreEntry(MyListEntry entry)` (mendukung fitur `"Urungkan"` pada `SnackBar`).

---

## 4. Integrasi Antar Halaman

1. **`SpotlightCarousel` (`lib/presentation/widgets/spotlight_carousel.dart`) & `HomeScreen` (`lib/presentation/screens/home_screen.dart`):**
   - `SpotlightCarousel` menerima opsional `bool Function(AnimeItem item)? isSavedBuilder` (atau `Set<String>` ID tersimpan) sehingga tombol kanan berubah dari `Icons.add_rounded` (`+`) menjadi `Icons.check_rounded` (warna `#0066FF`) bila anime sudah ada di My List.
   - `HomeScreen` meneruskan `onAddList: _handleToggleMyList` ke `SpotlightCarousel`, memanggil `MyListRepository.toggleSaveAnime(item)`, dan menampilkan `SnackBar` (`"Disimpan ke My List"` / `"Dihapus dari My List"`).
   - `HomeScreen` juga mendengarkan `MyListRepository` (`ListenableBuilder`) sehingga:
     - Bagian **"Continue watching"** di Beranda menampilkan **carousel horizontal kartu ringkas** (maksimal 5 anime `Watching` terbaru berisi poster, judul, `"Ep X/Y"`, progress bar + `%`, serta tombol `"Lihat semua"` menuju tab **My list**) bila sudah ada anime yang ditonton, atau tetap menampilkan `EmptyContinueWatching` saat kosong.
     - Tab indeks `3` (`My list`) merender `MyListScreen`.
2. **`AnimeDetailScreen` (`lib/presentation/screens/anime_detail_screen.dart`):**
   - Menerima opsional `MyListRepository? myListRepository` (default `MyListRepository.instance`).
   - Kedua tombol bookmark (ikon di kanan atas `SliverAppBar` dan tombol utama di bawah info anime) disinkronkan dengan `myListRepository.contains(...)` melalui `ListenableBuilder`.
   - Teks tombol diganti dari `'Daftar Tonton'` menjadi **`'Simpan Anime'`** (dan saat tersimpan menjadi **`'Tersimpan'`**).
   - Mengetuk tombol memanggil `toggleSaveFromDetail(detail)` (atau `toggleSaveAnime` jika masih loading dari `previewItem`); jika terhapus, tampilkan `SnackBar` dengan aksi `"Urungkan"` (`restoreEntry`) agar progres tidak hilang karena salah tekan.
3. **`AnimeWatchScreen` (`lib/presentation/screens/anime_watch_screen.dart`):**
   - Menerima opsional `MyListRepository? myListRepository` (default `MyListRepository.instance`).
   - Saat `initState` (episode awal) dan saat pengguna berpindah episode (`_selectEpisode` / `_goToNextEpisode`), memanggil `recordWatchProgress(detail: widget.anime, episodeNumber: ep.episodeNumber, episodeTitle: ep.title)` **hanya jika `widget.anime.hasVideoAvailable == true`**.
4. **Aksi Play vs Detail di `MyListScreen` & `Continue watching`:**
   - Mengetuk **area kartu** (atau kartu tanpa video lokal) membuka `AnimeDetailScreen`.
   - Mengetuk **tombol Play** (`#0066FF`) pada kartu `hasVideoAvailable == true` (atau tombol Play di banner `LANJUTKAN TONTON`) memuat `AnimeStreamService.getAnimeDetail(animeId)` dan langsung membuka `AnimeWatchScreen` di episode `targetEpisode = watchedEpisode > 0 ? watchedEpisode : 1` (disesuaikan ke daftar `detail.episodes`; jika gagal atau episode belum tersedia, fallback aman membuka `AnimeDetailScreen`).

---

## 5. Desain UI `MyListScreen` & Responsivitas Antislop

### 5.1 Dial Antislop
- **ENERGY:** `2`, **RHYTHM:** `2`, **MOTION:** `1` (transisi pilihan tab & progress bar halus tanpa efek berlebihan).

### 5.2 Hirarki `MyListScreen` (`lib/presentation/screens/my_list_screen.dart`)
1. **Header:**
   - Subjudul (`AppTypography.labelMedium`, `AppColors.textSecondary`): `"Koleksi anime pilihanmu."`
   - Judul utama (`AppTypography.headlineMedium`): `"My list"`
2. **3 Tab Status (`Watching`, `Saved`, `Completed`):**
   - Bar horizontal/flex dengan target sentuh minimal tinggi `44dp`:
     - `'Watching · <jumlah>'` (atau `'Watching'` jika 0)
     - `'Saved · <jumlah>'`
     - `'Completed · <jumlah>'`
   - Tab aktif memakai latar `AppColors.accentBlue` (`#0066FF`) dengan teks putih `#FFFFFF`, tab non-aktif memakai `AppColors.surfaceCard` (`#121212`) + border `#26262A`. Menggunakan `SingleChildScrollView(scrollDirection: Axis.horizontal)` / `Wrap` aman agar bebas overflow di layar `320px`.
3. **Banner Ringkas / Callout Tab Aktif:**
   - Kartu ringkas `#121212` dengan aksen border kiri/tepi tipis `#26262A`:
     - Saat tab `Watching` & ada item: `"LANJUTKAN TONTON"` + `"<N> anime siap dilanjutkan"` + tombol Play cepat ke anime terakhir.
     - Saat tab `Saved` & ada item: `"DAFTAR SIMPAN"` + `"<N> anime menunggu ditonton"`.
     - Saat tab `Completed` & ada item: `"SELESAI DITONTON"` + `"<N> anime telah tamat"`.
4. **Kartu Anime (`MyListAnimeCard`, `lib/presentation/widgets/my_list_anime_card.dart`):**
   - **Responsif `LayoutBuilder`:**
     - `maxWidth <= 600`: daftar 1 kolom vertikal.
     - `maxWidth > 600`: `ConstrainedBox(maxWidth: 960)` terpusat dengan grid 2 kolom.
   - **Isi Kartu (`#121212`, border `1px` `#26262A`, radius `12dp`):**
     - Poster portrait (`68x96`, radius `8dp`, `Image.network` + `AnimeImagePlaceholder` fallback).
     - Info tengah (`Expanded`):
       - Judul anime (`AppTypography.titleMedium`, `maxLines: 2, ellipsis`).
       - Episode terakhir (`entry.currentEpisodeTitle ?? ...`, atau badge `"Platform resmi"` jika `!entry.hasVideoAvailable`).
       - Teks jumlah episode (`"8 dari 12 episode"` atau `"Platform resmi · Progres 0%"`).
       - **Progress Bar:** `LinearProgressIndicator` (`ClipRRect` radius `4dp`, background `#26262A`, valueColor `#0066FF`) + baris bawah berisi `67% selesai · Sisa 33%`.
     - Aksi kanan:
       - Tombol utama (`44x44`): ikon Play `#0066FF` (bila `hasVideoAvailable == true`) atau ikon buka detail `Icons.open_in_new_rounded` / `Icons.chevron_right_rounded` (bila `!hasVideoAvailable`).
       - Tombol menu (`44x44`, `PopupMenuButton` / bottom sheet aksi): `Atur Episode`, `Pindah ke Watching / Saved / Completed`, dan `Hapus dari My List` (teks merah/peringatan jelas).
5. **3 State Wajib (R-27):**
   - **Loading:** Saat `init()` sedang membaca file lokal pertama kali.
   - **Empty:** Pesan spesifik per tab (contoh: `"Belum ada anime yang sedang ditonton."`, `"Belum ada anime tersimpan. Tekan + di Beranda atau Simpan Anime di halaman detail."`, `"Belum ada anime yang selesai ditonton."`) + tombol aksi `"Jelajahi Anime"` (pindah ke tab Explore).
   - **Error:** Penanganan error I/O dengan tombol `"Coba Lagi"`.
6. **Padding Bawah:** Ruang bawah `SafeArea(bottom: false)` + padding ekstra agar `CustomBottomNavBar` tidak pernah menutupi kartu terbawah.

