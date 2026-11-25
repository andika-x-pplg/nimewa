# Nimeva Anime Release Schedule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mengimplementasikan halaman **Jadwal** (`ScheduleScreen`) real-time berbasis AniList GraphQL API dengan navigasi pekan bergulir Minggu ke Sabtu, deteksi anime libur/tertunda, tampilan timeline responsif bertema Nimeva OLED, dan pengingat episode interaktif.

**Architecture:** Memisahkan model waktu dan domain (`schedule_entry.dart`), layanan pengambilan jadwal pekanan dengan auto-pagination, deteksi jeda antar-pekan, dan cache (`schedule_service.dart` + metode `executeGraphQL` di `anilist_api_client.dart`), serta komponen UI modular (`schedule_week_bar.dart`, `schedule_timeline_card.dart`, `schedule_screen.dart`) yang diintegrasikan ke `HomeScreen` tab ke-3.

**Tech Stack:** Flutter, Dart 3, AniList GraphQL API (`HttpClient`), `flutter_test`.

**Spec:** [2026-11-25-nimeva-schedule-screen-design.md](file:///e:/laragon/www/nimeva/docs/superpowers/specs/2026-11-25-nimeva-schedule-screen-design.md)

## Global Constraints
- Warna wajib memakai `AppColors`: latar `#000000` (`bgPrimary`), kartu `#121212` (`surfaceCard`), elevated `#1C1C1E` (`surfaceElevated`), border `#26262A` (`borderSubtle`), aksen utama `#0066FF` (`accentBlue`), aksen rating/libur `#FFB800` (`accentAmber`), teks `#FFFFFF`/`#A1A1AA`/`#71717A`.
- Tipografi wajib memakai `AppTypography`.
- Larangan antislop: dilarang memakai karakter em-dash (`—`), dilarang menggunakan gradien biru-ungu, glow berlebihan, atau tombol non-fungsional.
- Target sentuh minimum setiap elemen interaktif: `44 x 44` dp (`antislop-layoutmobile`).
- Tata letak responsif dengan `LayoutBuilder`: 1 kolom timeline untuk `maxWidth <= 600`, grid 2 kolom terpusat (`ConstrainedBox(maxWidth: 960)`) untuk `maxWidth > 600`.
- Tidak ada konten dewasa (`isAdult == true`).
- Zona waktu mengikuti lokal perangkat (`DateTime.now().toLocal()`), bukan *hardcode* GMT+7.
- Rentang pekan dimulai **Minggu** (`weekday == 7`, offset `0`) hingga **Sabtu** (`offset 6`) dalam urutan kiri ke kanan, otomatis berganti pekan saat masuk hari Minggu baru.

## Review Focus
1. **Perbatasan pergantian hari & tengah malam (00:00-00:30 lokal) dan pergantian pekan di hari Minggu baru:** Item yang tayang pukul `00:30` hari Minggu harus masuk ke slot Minggu pekan baru (bukan Sabtu pekan lama), dan saat `now` berpindah ke Minggu tanggal 29, tanggal 22-28 otomatis hilang dari bar pekan.
2. **Episode tayang lebih awal di hari yang sama vs hari depan (contoh `06:28` dilihat pukul `07:00`):** Episode `06:28` pada hari yang sama dengan `now = 07:00` harus berstatus `released` (`"Sudah rilis · 06:28"`), sedangkan episode `06:28` di hari Kamis (saat `now` masih Rabu) harus berstatus `upcoming` (`"Rilis 06:28 · Dalam ..."`).
3. **Pagination >50 item & deduplikasi anime libur antar-pekan:** Jika `pageInfo.hasNextPage == true` pada hari Senin-Rabu, halaman berikutnya tetap diambil sehingga Kamis-Sabtu tidak kosong; jika anime pekan lalu tidak tayang pekan ini tapi belum punya `nextAiringEpisode` atau selisihnya `< 10 hari` (misalnya anime baru tamat), ia tidak boleh salah diklasifikasikan sebagai libur.
4. **Mode gagal jaringan pertama kali vs cache kedaluwarsa saat offline:** Jika cache pekan belum ada dan HTTP gagal, `ScheduleService` melempar exception agar `ScheduleScreen` merender Error State dengan tombol `"Coba Lagi"` (tanpa menggantung `pumpAndSettle` di widget test); jika cache pekan sudah ada dan muat ulang gagal, kembalikan cache dengan `isStaleCache = true`.
5. **Overflow mobile 320px/360px & tab target di bar 7 hari serta penutupan oleh bottom nav:** Judul anime panjang pada layar selebar `320px` harus terpotong rapi dengan `ellipsis` tanpa `RenderFlex overflow`, seluruh 7 kolom hari pas dalam satu baris, dan item terbawah tetap bisa digulir melewati area `CustomBottomNavBar`.

---

### Task 1: Domain Models & Pure Date/Week Helper (`ScheduleEntry`, `WeeklyScheduleResult`, `ScheduleDateHelper`)

**Files:**
- Create: `lib/data/models/schedule_entry.dart`
- Test: `test/data/schedule_entry_test.dart`

**Interfaces:**
- Produces:
  - `enum ScheduleReleaseStatus { released, upcoming, delayedOrHiatus }`
  - `class ScheduleEntry` with fields `scheduleId`, `mediaId`, `title`, `japaneseTitle`, `posterUrl`, `bannerUrl`, `rating`, `genres`, `synopsis`, `format`, `episodeNumber`, `airingAt`, `isHiatusOrDelayed`, `nextAiringAt`, `delayNote`, `hasVideoAvailable`, and methods `ScheduleReleaseStatus statusAt(DateTime now)`, `String formattedTime()`, `String formatStatusText(DateTime now)`, `AnimeItem toAnimeItem()`.
  - `class WeeklyScheduleResult` with fields `weekStart`, `weekEnd`, `entriesByDateKey`, `isStaleCache`, and helper `List<ScheduleEntry> entriesForDate(DateTime date)`.
  - `abstract final class ScheduleDateHelper` with `DateTime weekStartSunday(DateTime now)`, `List<DateTime> weekDays(DateTime now)`, `String dateKey(DateTime dt)`, `String shortDayLabel(DateTime dt)`, `String monthYearHeader(DateTime dt)`, `String gmtOffsetLabel(DateTime dt)`, `String sectionHeaderTitle(DateTime selectedDate, DateTime now)`.

- [ ] **Step 1: Write the failing unit tests in `test/data/schedule_entry_test.dart`**

Write tests verifying:
- `ScheduleDateHelper.weekStartSunday`: for Wednesday 2026-11-25 returns Sunday 2026-11-22 00:00:00; for Sunday 2026-11-29 returns Sunday 2026-11-29 00:00:00 (rolling off Nov 22-28).
- `ScheduleDateHelper.weekDays` returns 7 consecutive days starting `Min` (22) through `Sab` (28).
- `ScheduleDateHelper.shortDayLabel` maps Sunday..Saturday to `Min, Sen, Sel, Rab, Kam, Jum, Sab`.
- `ScheduleDateHelper.sectionHeaderTitle` returns `'Tayang Hari Ini'` for today, `'Sudah Tayang · Min, 22 Nov'` for past date, `'Akan Tayang · Kam, 26 Nov'` for future date.
- `ScheduleEntry.statusAt` and `formatStatusText`:
  - At `07:00` on Wednesday Nov 25: an item at `06:28` Nov 25 is `ScheduleReleaseStatus.released` (`"Baru rilis · 06:28"`), an item at `05:00` Nov 25 is `released` (`"Sudah rilis · 05:00"`), an item at `06:28` Thursday Nov 26 is `upcoming` (`"Rilis 06:28 · Dalam 23j 28m"`), an item at `19:30` Nov 25 is `upcoming` (`"Rilis 19:30 · Dalam 12j 30m"`), and a delayed item (`isHiatusOrDelayed: true`) returns `delayedOrHiatus` with its `delayNote`.
- `ScheduleEntry.toAnimeItem()` preserves `mediaId.toString()` as `id`, `aniListId`, `title`, `posterUrl`, `hasVideoAvailable`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/data/schedule_entry_test.dart`
Expected: FAIL (file `package:nimeva/data/models/schedule_entry.dart` not found).

- [ ] **Step 3: Implement `ScheduleDateHelper`, `ScheduleEntry`, and `WeeklyScheduleResult` in `lib/data/models/schedule_entry.dart`**
Implement all models, pure week/date helpers, countdown formatter (minutes/hours/days without em-dash), and `toAnimeItem()`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/data/schedule_entry_test.dart`
Expected: PASS (all assertions green).

- [ ] **Step 5: Commit**
```bash
git add lib/data/models/schedule_entry.dart test/data/schedule_entry_test.dart
git commit -m "feat(schedule): add ScheduleEntry, WeeklyScheduleResult, and ScheduleDateHelper"
```

---

### Task 2: AniList Weekly Schedule GraphQL Service (`AniListApiClient.executeGraphQL` + `ScheduleService`)

**Files:**
- Modify: `lib/data/services/anilist_api_client.dart:640-665`
- Create: `lib/data/services/schedule_service.dart`
- Test: `test/data/schedule_service_test.dart`

**Interfaces:**
- Consumes: `ScheduleEntry`, `WeeklyScheduleResult`, `ScheduleDateHelper` from Task 1; `AnimeStreamResolver.hasCompleteEpisodes` from `lib/data/services/anime_stream_resolver.dart`.
- Produces:
  - `AniListApiClient.executeGraphQL(String query, Map<String, dynamic> variables)` (public wrapper around `_postGraphQL`).
  - `typedef GraphQLRequester = Future<Map<String, dynamic>> Function(String query, Map<String, dynamic> variables);`
  - `class ScheduleService` with constructor `ScheduleService({AniListApiClient? apiClient, GraphQLRequester? graphQLRequester, Duration cacheTtl = const Duration(minutes: 10)})` and `Future<WeeklyScheduleResult> fetchWeeklySchedule({DateTime? now, bool forceRefresh = false})`.

- [ ] **Step 1: Write the failing tests in `test/data/schedule_service_test.dart`**

Write tests using an injected mock `graphQLRequester` covering:
- Auto-pagination across multiple pages (`hasNextPage: true` on page 1, `false` on page 2) so entries from both Sunday/Monday and Thursday/Saturday populate `entriesByDateKey`.
- Filters out `isAdult: true` entries and empty titles, and assigns `hasVideoAvailable` via `AnimeStreamResolver.hasCompleteEpisodes`.
- Boundary midnight handling: an airing timestamp at `00:30` local Sunday is grouped under that Sunday's `dateKey`, not Saturday.
- Delay/skip detection: when an anime with `status: 'RELEASING'` aired in `previousWeek` (e.g. Saturday Nov 21 at `17:00`, episode `1221`) is absent from `currentWeek` and has `nextAiringEpisode` `>= 10 days` later (Dec 5, episode `1222`), `ScheduleService` adds a `ScheduleEntry` into Saturday Nov 28 at `17:00` with `isHiatusOrDelayed: true`, `episodeNumber: 1222`, and `delayNote: 'Libur minggu ini · Tayang lagi 5 Des'`. Conversely, a finished/no-next-episode anime missing from current week (`nextAiringEpisode == null` or `< 10 days`) is NOT marked delayed.
- Cache behavior: second call within TTL returns cached result without calling `graphQLRequester`; `forceRefresh: true` bypasses cache; on network exception with expired cache, returns stale cache with `isStaleCache: true`; on network exception with no cache, rethrows exception.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/data/schedule_service_test.dart`
Expected: FAIL (file `schedule_service.dart` / method `executeGraphQL` missing).

- [ ] **Step 3: Expose `executeGraphQL` on `AniListApiClient` and implement `ScheduleService`**
- In `lib/data/services/anilist_api_client.dart`, expose `Future<Map<String, dynamic>> executeGraphQL(String query, Map<String, dynamic> variables) => _postGraphQL(query, variables);`.
- Create `lib/data/services/schedule_service.dart` implementing paginated `airingSchedules` queries for current week (`weekStart..weekEnd`) and previous week (`prevWeekStart..weekStart`), filtering, delay detection, week-keyed in-memory caching, and stale-cache vs rethrow failure contract.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/data/schedule_service_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/data/services/anilist_api_client.dart lib/data/services/schedule_service.dart test/data/schedule_service_test.dart
git commit -m "feat(schedule): add ScheduleService with weekly pagination, delay detection, and caching"
```

---

### Task 3: Weekly Selector Bar & Timeline Card Widgets (`ScheduleWeekBar` & `ScheduleTimelineCard`)

**Files:**
- Create: `lib/presentation/widgets/schedule_week_bar.dart`
- Create: `lib/presentation/widgets/schedule_timeline_card.dart`
- Test: `test/presentation/widgets/schedule_widgets_test.dart`

**Interfaces:**
- Consumes: `ScheduleEntry`, `ScheduleReleaseStatus`, `ScheduleDateHelper`, `AppColors`, `AppTypography`, `AnimeImagePlaceholder`.
- Produces:
  - `class ScheduleWeekBar extends StatelessWidget`: props `List<DateTime> days`, `DateTime selectedDate`, `DateTime today`, `Set<String> reminderDateKeys`, `ValueChanged<DateTime> onDaySelected`.
  - `class ScheduleTimelineCard extends StatelessWidget`: props `ScheduleEntry entry`, `DateTime now`, `bool isReminded`, `bool isLastInColumn`, `bool showTimelineRail`, `VoidCallback onTap`, `VoidCallback? onReminderToggle`.

- [ ] **Step 1: Write the failing widget tests in `test/presentation/widgets/schedule_widgets_test.dart`**

Write tests verifying:
- `ScheduleWeekBar` renders `'NOVEMBER 2026'`, dynamic local timezone label (`ScheduleDateHelper.gmtOffsetLabel(today)`), all 7 days `'Min'`..`'Sab'` left-to-right with dates `'22'`..`'28'` without overflow on a `320px` wide surface, minimum height `>= 44` per day cell, active blue styling on `selectedDate`, and invokes `onDaySelected` when tapping Thursday (`26`).
- `ScheduleTimelineCard` renders poster (`Image.network` or `AnimeImagePlaceholder`), anime title, `'Episode 8'`, time `'06:28'`, status `'Baru rilis · 06:28'` when `now` is `07:00`, reminder bell toggle on `upcoming` and `delayedOrHiatus` cards (with `>= 44x44` hit target), amber `'Libur minggu ini'` text when `isHiatusOrDelayed == true`, play icon when `released` and `hasVideoAvailable == true`, chevron when `released` and `hasVideoAvailable == false`, and handles long titles without overflow on `320px` width.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/schedule_widgets_test.dart`
Expected: FAIL (widget files do not exist).

- [ ] **Step 3: Implement `ScheduleWeekBar` and `ScheduleTimelineCard`**
Build both widgets strictly using `AppColors` (`#000000`, `#121212`, `#1C1C1E`, `#26262A`, `#0066FF`, `#FFB800`) and `AppTypography`, zero em-dashes, `AnimatedContainer` (`150ms`) for active day selection, proper `Semantics` labels, and safe text ellipsis.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/schedule_widgets_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/widgets/schedule_week_bar.dart lib/presentation/widgets/schedule_timeline_card.dart test/presentation/widgets/schedule_widgets_test.dart
git commit -m "feat(schedule): add ScheduleWeekBar and ScheduleTimelineCard widgets"
```

---

### Task 4: Responsive `ScheduleScreen` & Integration with `HomeScreen`

**Files:**
- Create: `lib/presentation/screens/schedule_screen.dart`
- Modify: `lib/presentation/screens/home_screen.dart:1-35,200-220`
- Test: `test/presentation/screens/schedule_screen_test.dart`
- Modify/Verify: `test/presentation/screens/home_screen_test.dart`

**Interfaces:**
- Consumes: `ScheduleService`, `ScheduleEntry`, `WeeklyScheduleResult`, `ScheduleDateHelper`, `ScheduleWeekBar`, `ScheduleTimelineCard`, `AnimeItem`, `HomeScreen`.
- Produces:
  - `class ScheduleScreen extends StatefulWidget` with optional `ScheduleService? scheduleService`, `void Function(AnimeItem anime)? onAnimeTap`, `DateTime Function()? nowProvider`.
  - `HomeScreen` optional parameter `ScheduleService? scheduleService` (passed to `ScheduleScreen` in `case 2:` of `_buildBody`).

- [ ] **Step 1: Write the failing widget tests in `test/presentation/screens/schedule_screen_test.dart`**

Write tests using mock `ScheduleService` and fixed `nowProvider` (`2026-11-25 07:00:00`) covering:
- Initial loading state shows `'Memuat jadwal anime...'`.
- Loaded state displays `'Jadwal Rilis'`, `'NOVEMBER 2026'`, Wednesday `25` selected by default (`'Tayang Hari Ini'`), and shows both already-released `06:28` item (`'Baru rilis · 06:28'`) and upcoming `19:30` item (`'Rilis 19:30 · Dalam 12j 30m'`).
- Tapping past day (`Min 22`) updates header to `'Sudah Tayang · Min, 22 Nov'` and displays Sunday's lineup; tapping future day (`Kam 26`) updates header to `'Akan Tayang · Kam, 26 Nov'` and displays Thursday's items with countdown and delayed/hiatus item badge.
- Week rollover: rendering with `nowProvider = () => DateTime(2026, 11, 29, 9, 0)` shows `Min 29`..`Sab 5` and no longer shows `22`.
- Reminder toggle & header filter: tapping bell on an upcoming card turns on reminder + shows SnackBar; tapping header bell switches to `"Hanya Pengingat"` mode, and empty reminder state offers reset button.
- Card tap triggers `onAnimeTap(entry.toAnimeItem())`.
- Error state on failed fetch displays error message and `'Coba Lagi'` button, which retries on tap; stale cache state displays offline banner.
- Responsive layout test: renders cleanly without overflow at `360x780` (1-column timeline) and `900x800` (2-column constrained grid `<= 960px`).

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/screens/schedule_screen_test.dart`
Expected: FAIL (`schedule_screen.dart` not found).

- [ ] **Step 3: Implement `ScheduleScreen` and wire into `HomeScreen`**
- Implement `ScheduleScreen` in `lib/presentation/screens/schedule_screen.dart` with `LayoutBuilder` adaptive 1-col / 2-col grid (`largeScreenMinWidth = 600`), pull-to-refresh (`RefreshIndicator`), `SafeArea`, bottom padding for `CustomBottomNavBar`, header reminder filter button (`>= 44x44`), and loading/error/empty states.
- Update `lib/presentation/screens/home_screen.dart` to accept optional `ScheduleService? scheduleService` and replace `_buildPlaceholderTab('Jadwal Tayang Anime', ...)` in `case 2:` with `ScheduleScreen(scheduleService: widget.scheduleService, onAnimeTap: _openAnimeDetail)`.

- [ ] **Step 4: Run tests to verify `schedule_screen_test.dart` and `home_screen_test.dart` pass**
Run: `flutter test test/presentation/screens/schedule_screen_test.dart test/presentation/screens/home_screen_test.dart`
Expected: PASS (no hangs on HTTP error in `home_screen_test.dart`, all schedule tests green).

- [ ] **Step 5: Commit**
```bash
git add lib/presentation/screens/schedule_screen.dart lib/presentation/screens/home_screen.dart test/presentation/screens/schedule_screen_test.dart
git commit -m "feat(schedule): implement responsive ScheduleScreen and integrate into HomeScreen"
```

---

### Task 5: Full Verification & Antislop Delivery Gate

**Files:**
- Verify all created and modified files in `lib/` and `test/`.

- [ ] **Step 1: Verify zero em-dashes and rule compliance across new UI files**
Run: `git grep -n "—" lib/presentation/screens/schedule_screen.dart lib/presentation/widgets/schedule_week_bar.dart lib/presentation/widgets/schedule_timeline_card.dart lib/data/models/schedule_entry.dart lib/data/services/schedule_service.dart`
Expected: No matches (exit code 1).

- [ ] **Step 2: Run static analyzer and full test suite**
Run: `flutter analyze; flutter test`
Expected: `No issues found!` and `All tests passed!`.

