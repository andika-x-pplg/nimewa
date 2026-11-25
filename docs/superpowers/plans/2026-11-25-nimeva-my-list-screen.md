# Nimeva My List & Watch Progress Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengimplementasikan halaman **My list** (`Watching`, `Saved`, `Completed`), penyimpanan permanen lokal `MyListRepository`, tombol simpan dari Beranda (`+`) dan Detail (`"Simpan Anime"`), serta pelacakan progres persentase otomatis dari `AnimeWatchScreen`.

**Architecture:** `MyListRepository` (`ChangeNotifier` + file JSON lokal `dart:io`) menjadi pusat data tunggal yang menormalkan ID melalui `AnimeStreamResolver.detectAnimeKey`, lalu diobservasi secara reaktif oleh `HomeScreen` (`SpotlightCarousel`, `ContinueWatchingStrip`, tab `MyListScreen`), `AnimeDetailScreen`, dan `AnimeWatchScreen`.

**Tech Stack:** Flutter, Dart 3 (`dart:io`, `dart:convert`), `flutter_test`.

**Spec:** [2026-11-25-nimeva-my-list-screen-design.md](file:///e:/laragon/www/nimeva/docs/superpowers/specs/2026-11-25-nimeva-my-list-screen-design.md)

## Global Constraints
- Warna wajib memakai `AppColors`: `#000000` (`bgPrimary`), `#121212` (`surfaceCard`), `#1C1C1E` (`surfaceElevated`), `#26262A` (`borderSubtle`), `#0066FF` (`accentBlue`), `#FFB800` (`accentAmber`), teks `#FFFFFF`/`#A1A1AA`/`#71717A`.
- Tipografi wajib memakai `AppTypography`.
- Larangan antislop: nol karakter em-dash (`—`), nol gradien biru-ungu, nol tombol dekoratif tanpa aksi nyata, target sentuh minimal `44 x 44` dp.
- Tata letak responsif `LayoutBuilder`: 1 kolom (`maxWidth <= 600`) dan 2 kolom terpusat `ConstrainedBox(maxWidth: 960)` (`maxWidth > 600`).
- Teks tombol simpan di `AnimeDetailScreen` wajib **`'Simpan Anime'`** (bukan `'Daftar Tonton'`), dan `'Tersimpan'` saat sudah masuk My List.
- Anime tanpa video lokal (`hasVideoAvailable == false`) tetap bisa disimpan ke `Saved` dengan `0%` (`"Platform resmi · Progres 0%"`), tidak naik otomatis dari pemutar video, namun mendukung ubah status/episode manual dan hapus.

## Review Focus
1. **Normalisasi ID lintas sumber (`demon-slayer` vs `101922` vs `41370`):** Menyimpan dari Beranda lalu membuka dari Explore/Detail/Watch tidak boleh membuat 2 entri duplikat atau gagal mendeteksi status `'Tersimpan'`.
2. **Pembagian dengan nol & persentase melampaui 100% (`totalEpisodes == 0` atau movie `1` episode):** Persentase selesai dan sisa selalu berada dalam rentang `0..100`, tanpa `NaN`, dan movie (`1` episode) langsung `100%` (`Completed`) saat diputar.
3. **Anime tanpa video lokal (`hasVideoAvailable == false`):** `recordWatchProgress` wajib menolak menaikkan progres otomatis, kartu menampilkan `"Platform resmi · Progres 0%"`, tidak menampilkan tombol Play palsu, dan dialog atur episode manual tetap mengizinkan input meski `totalEpisodes == 0`.
4. **Hapus & `"Urungkan"` (*Undo*):** Menghapus item (baik dari menu My List maupun tombol `"Tersimpan"` di Detail) memunculkan `SnackBar` dengan `"Urungkan"` yang mengembalikan entri beserta progres episode sebelumnya secara utuh.
5. **Overflow mobile `320px` & bottom nav clearance:** Tab bar `Watching · N`, `Saved · N`, `Completed · N`, kartu progres `MyListAnimeCard`, dan strip horizontal `ContinueWatchingStrip` bebas `RenderFlex overflow` pada layar `320px` dan tidak tertutup `CustomBottomNavBar`.

---

### Task 1: Model `MyListEntry`, `MyListStatus` & Perhitungan Persentase

**Files:**
- Create: `lib/data/models/my_list_entry.dart`
- Test: `test/data/my_list_entry_test.dart`

**Interfaces:**
- Produces:
  - `enum MyListStatus { watching, saved, completed }`
  - `class MyListEntry` with fields `canonicalKey`, `animeId`, `aniListId`, `title`, `japaneseTitle`, `posterUrl`, `backdropUrl`, `rating`, `releaseYear`, `genres`, `description`, `totalEpisodes`, `watchedEpisode`, `currentEpisodeTitle`, `status`, `hasVideoAvailable`, `updatedAt`.
  - Getters & helpers: `int get completedPercent`, `int get remainingPercent`, `double get progressFraction`, `String get progressSummaryText`, `String get percentSummaryText`, `AnimeItem toAnimeItem()`, `MyListEntry copyWith(...)`, `Map<String, dynamic> toJson()`, `factory MyListEntry.fromJson(Map<String, dynamic> json)`, `static int parseTotalEpisodesFromInfo(String episodeInfo)`.

- [ ] **Step 1: Write failing unit tests in `test/data/my_list_entry_test.dart`**
Test `completedPercent` / `remainingPercent` (`8/12 -> 67% selesai · Sisa 33%`, `0/12 -> 0%`, `totalEpisodes == 0 -> 0%`, `status == completed -> 100%`), `progressSummaryText` for `!hasVideoAvailable` at `0%` (`'Platform resmi · Progres 0%'`), `parseTotalEpisodesFromInfo('SUB · 24 EPS (Tamat)') == 24` and `'SUB · MOVIE' == 1`, `toJson`/`fromJson` roundtrip, and `toAnimeItem()`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/data/my_list_entry_test.dart`
Expected: FAIL (`my_list_entry.dart` not found).

- [ ] **Step 3: Implement `lib/data/models/my_list_entry.dart`**
Implement `MyListStatus`, `MyListEntry`, safe math clamping `0..100`, JSON serialization, and `toAnimeItem()`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/data/my_list_entry_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/data/models/my_list_entry.dart test/data/my_list_entry_test.dart
git commit -m "feat(mylist): add MyListEntry model with percentage and JSON serialization"
```

---

### Task 2: `MyListRepository` dengan Normalisasi ID & Persistensi JSON Lokal

**Files:**
- Create: `lib/data/services/my_list_repository.dart`
- Test: `test/data/my_list_repository_test.dart`

**Interfaces:**
- Consumes: `MyListEntry`, `MyListStatus` (Task 1), `AnimeItem`, `AnimeDetail`, `AnimeStreamResolver.detectAnimeKey`, `AnimeStreamResolver.hasCompleteEpisodes`.
- Produces:
  - `class MyListRepository extends ChangeNotifier`:
    - `static final MyListRepository instance`
    - `MyListRepository({File? storageFile, bool disablePersistence = false, DateTime Function()? clock})`
    - `Future<void> init()`, `List<MyListEntry> get allEntries`, `List<MyListEntry> entriesByStatus(MyListStatus status)`, `int countByStatus(MyListStatus status)`
    - `bool contains(String animeId, {int aniListId = 0, String title = ''})`, `MyListEntry? findEntry(...)`
    - `Future<bool> toggleSaveAnime(AnimeItem item, {int? totalEpisodes})`
    - `Future<bool> toggleSaveFromDetail(AnimeDetail detail)`
    - `Future<void> recordWatchProgress({required AnimeDetail detail, required int episodeNumber, String? episodeTitle})`
    - `Future<void> updateStatus(String keyOrId, MyListStatus newStatus)`
    - `Future<void> updateEpisodeProgress(String keyOrId, int episodeNumber)`
    - `Future<MyListEntry?> removeEntry(String keyOrId)`, `Future<void> restoreEntry(MyListEntry entry)`

- [ ] **Step 1: Write failing unit tests in `test/data/my_list_repository_test.dart`**
Test saving via `toggleSaveAnime` & `toggleSaveFromDetail` (canonical deduplication across `'demon-slayer'` and `'101922'`), `recordWatchProgress` advancing Ep 1 -> Ep 2 -> Ep 12 (`Saved -> Watching -> Completed`), `recordWatchProgress` ignoring `!hasVideoAvailable` entries, `updateStatus` (`completed` sets `watchedEpisode = totalEpisodes`, `saved` resets `0`), `updateEpisodeProgress` on `totalEpisodes == 0` external anime, `removeEntry`/`restoreEntry`, and JSON persistence roundtrip using a temp `File`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/data/my_list_repository_test.dart`
Expected: FAIL (`my_list_repository.dart` missing).

- [ ] **Step 3: Implement `lib/data/services/my_list_repository.dart`**
Implement `MyListRepository` with idempotent `init()`, safe I/O persistence wrapped in `try/catch`, canonical key matching (`detectAnimeKey` + `aniListId` + `animeId`), and authoritative `hasCompleteEpisodes` check.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/data/my_list_repository_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/data/services/my_list_repository.dart test/data/my_list_repository_test.dart
git commit -m "feat(mylist): add MyListRepository with canonical ID sync and JSON persistence"
```

---

### Task 3: Widget `MyListAnimeCard` dan `ContinueWatchingStrip`

**Files:**
- Create: `lib/presentation/widgets/my_list_anime_card.dart`
- Create: `lib/presentation/widgets/continue_watching_strip.dart`
- Test: `test/presentation/widgets/my_list_widgets_test.dart`

**Interfaces:**
- Consumes: `MyListEntry`, `MyListStatus`, `AppColors`, `AppTypography`, `AnimeImagePlaceholder`.
- Produces:
  - `class MyListAnimeCard extends StatelessWidget`: props `MyListEntry entry`, `VoidCallback onTap`, `VoidCallback? onPlayTap`, `ValueChanged<MyListStatus>? onStatusChanged`, `VoidCallback? onEditProgress`, `VoidCallback? onDelete`.
  - `class ContinueWatchingStrip extends StatelessWidget`: props `List<MyListEntry> entries`, `VoidCallback onSeeAllTap`, `ValueChanged<MyListEntry> onEntryTap`, `ValueChanged<MyListEntry>? onPlayTap`.

- [ ] **Step 1: Write failing widget tests in `test/presentation/widgets/my_list_widgets_test.dart`**
Verify `MyListAnimeCard` renders poster, title, episode text (`'8 dari 12 episode'`), `LinearProgressIndicator`, `'67% selesai · Sisa 33%'`, Play button (`>= 44x44`) when `hasVideoAvailable`, `'Platform resmi · Progres 0%'` + detail icon when `!hasVideoAvailable`, menu actions (`Atur Episode`, `Pindah Status`, `Hapus dari My List`), and zero overflow on `320px` width; verify `ContinueWatchingStrip` caps display to 5 cards, shows `'Continue watching'` + `'Lihat semua'`, and triggers callbacks cleanly.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/my_list_widgets_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `my_list_anime_card.dart` and `continue_watching_strip.dart`**
Build both widgets strictly using `AppColors` and `AppTypography`, `44x44` min tap targets, zero em-dashes, and clean `PopupMenuButton` action menu.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/my_list_widgets_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/widgets/my_list_anime_card.dart lib/presentation/widgets/continue_watching_strip.dart test/presentation/widgets/my_list_widgets_test.dart
git commit -m "feat(mylist): add MyListAnimeCard and ContinueWatchingStrip widgets"
```

---

### Task 4: Halaman `MyListScreen` Responsif dengan 3 Tab & Aksi Lengkap

**Files:**
- Create: `lib/presentation/screens/my_list_screen.dart`
- Test: `test/presentation/screens/my_list_screen_test.dart`

**Interfaces:**
- Consumes: `MyListRepository`, `MyListEntry`, `MyListStatus`, `MyListAnimeCard`, `AnimeStreamService`, `AnimeDetailScreen`, `AnimeWatchScreen`.
- Produces:
  - `class MyListScreen extends StatefulWidget` with optional `MyListRepository? repository`, `AnimeStreamService? streamService`, `void Function(AnimeItem anime)? onAnimeTap`, `VoidCallback? onExploreTap`.

- [ ] **Step 1: Write failing widget tests in `test/presentation/screens/my_list_screen_test.dart`**
Verify:
- 3 tabs (`Watching · N`, `Saved · N`, `Completed · N`) filter entries accurately and switch active blue highlight.
- Callout banner updates per active tab and quick Play launches `AnimeWatchScreen` on `watchedEpisode` (or `1` for `Saved`).
- Tapping card opens `AnimeDetailScreen`; tapping Play on `hasVideoAvailable` resolves detail and opens `AnimeWatchScreen` on `watchedEpisode`.
- Deleting an entry removes it and shows SnackBar with `'Urungkan'` which restores it; changing status via menu moves item across tabs; `'Atur Episode'` dialog updates episode & percentage (`0 -> 50%` or `100%`).
- Empty state per tab renders `'Jelajahi Anime'` calling `onExploreTap`; responsive `LayoutBuilder` renders 1 column at `320px` and 2-column centered (`maxWidth: 960`) at `900px` without overflow.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/screens/my_list_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `lib/presentation/screens/my_list_screen.dart`**
Implement `MyListScreen` with `ListenableBuilder` on `MyListRepository`, horizontal 3-tab chip row (`>= 44dp` height), callout banner, `LayoutBuilder` 1-col/2-col sliver layout, direct-play resolver (`AnimeWatchScreen` with fallback to `AnimeDetailScreen`), episode progress dialog, status change + delete with Undo SnackBar, and loading/empty/error states.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/screens/my_list_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/screens/my_list_screen.dart test/presentation/screens/my_list_screen_test.dart
git commit -m "feat(mylist): implement responsive MyListScreen with 3 tabs, progress edit, and delete"
```

---

### Task 5: Integrasi ke `HomeScreen`, `SpotlightCarousel`, `AnimeDetailScreen`, dan `AnimeWatchScreen`

**Files:**
- Modify: `lib/presentation/widgets/spotlight_carousel.dart:10-25,379-406`
- Modify: `lib/presentation/screens/home_screen.dart:1-35,140-230`
- Modify: `lib/presentation/screens/anime_detail_screen.dart:14-45,120-150,406-442`
- Modify: `lib/presentation/screens/anime_watch_screen.dart:11-60,360-440`
- Test: `test/presentation/screens/my_list_integration_test.dart`

**Interfaces:**
- Consumes: `MyListRepository`, `MyListScreen`, `ContinueWatchingStrip`.
- Produces: End-to-end persistence & live UI sync across Home (`+` & `Continue watching` & `My list` tab), Detail (`Simpan Anime` / `Tersimpan` + AppBar icon + Undo), and Watch (automatic episode progress recording).

- [ ] **Step 1: Write failing integration tests in `test/presentation/screens/my_list_integration_test.dart`**
Verify:
- Tapping `+` in `HomeScreen` `SpotlightCarousel` saves anime to `MyListRepository` (`Saved`), switches icon to check (`Icons.check_rounded`), and displays it inside the `My list` tab (`Saved` tab).
- In `AnimeDetailScreen`, button shows `'Simpan Anime'` (never `'Daftar Tonton'`), tapping saves to `MyListRepository` and updates both AppBar icon and button label to `'Tersimpan'`; tapping `'Tersimpan'` removes with `'Urungkan'` SnackBar.
- Opening `AnimeWatchScreen` for a playable anime records episode `1`, and advancing to episode `2` automatically increments `MyListRepository` progress (`Saved -> Watching`) and surfaces it in `HomeScreen`'s `ContinueWatchingStrip`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/screens/my_list_integration_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement wiring in `SpotlightCarousel`, `HomeScreen`, `AnimeDetailScreen`, and `AnimeWatchScreen`**
- Add `bool Function(AnimeItem item)? isSavedBuilder` to `SpotlightCarousel` (showing `Icons.check_rounded` when true).
- Wire `MyListRepository` into `HomeScreen` (`onAddList`, `ContinueWatchingStrip` when `Watching` non-empty, `MyListScreen` in `case 3:`).
- Wire `MyListRepository` into `AnimeDetailScreen` (both AppBar bookmark and `'Simpan Anime'`/`'Tersimpan'` button + `'Urungkan'` SnackBar).
- Wire `MyListRepository.recordWatchProgress` into `AnimeWatchScreen` on episode init and episode change when `hasVideoAvailable == true`.

- [ ] **Step 4: Run focused integration & existing screen tests**
Run: `flutter test test/presentation/screens/my_list_integration_test.dart test/presentation/screens/home_screen_test.dart test/presentation/screens/anime_detail_screen_test.dart test/presentation/screens/anime_watch_screen_test.dart test/presentation/widgets/spotlight_carousel_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/widgets/spotlight_carousel.dart lib/presentation/screens/home_screen.dart lib/presentation/screens/anime_detail_screen.dart lib/presentation/screens/anime_watch_screen.dart test/presentation/screens/my_list_integration_test.dart
git commit -m "feat(mylist): integrate MyListRepository across Home, Detail, and Watch screens"
```

---

### Task 6: Verifikasi Akhir, Antislop Delivery Gate & Self-Review

**Files:**
- Verify all created and modified files.

- [ ] **Step 1: Verify zero em-dashes and zero `'Daftar Tonton'` text remaining on detail button**
Run: `git grep -n "—" lib/data/models/my_list_entry.dart lib/data/services/my_list_repository.dart lib/presentation/widgets/my_list_anime_card.dart lib/presentation/widgets/continue_watching_strip.dart lib/presentation/screens/my_list_screen.dart ; git grep -n "Daftar Tonton" lib/presentation/screens/anime_detail_screen.dart`
Expected: No matches.

- [ ] **Step 2: Run static analyzer and full test suite**
Run: `flutter analyze; flutter test`
Expected: `No issues found!` and `All tests passed!`.

