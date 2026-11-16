# Nimeva Home Screen Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun layout halaman Home aplikasi mobile streaming anime "Nimeva" di Flutter dengan tema Cinematic Obsidian & Crimson, bebas AI-slop, dilengkapi header profil, carousel 5 anime akurat, empty state continue watching, dan bottom navigation bar.

**Architecture:** Arsitektur modular feature-first memisahkan core theme & design tokens (`core/theme/`), data model & mock repository (`data/`), serta modular presentation widgets (`presentation/widgets/` & `presentation/screens/`) yang disatukan di `HomeScreen`.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, Material 3 (`useMaterial3: true`), flutter_test.

**Spec:** [design_doc.md](file:///C:/Users/Administrator/.gemini/antigravity/brain/229aafc4-8b5f-49b2-a7f8-7a363b91d9bc/design_doc.md)

## Global Constraints
- Tema visual: Cinematic Obsidian & Crimson (Obsidian `#0B0D13`, Crimson `#E50914`, Amber `#FFB703`).
- Larangan: Tidak ada gradien ungu neon slop, tidak ada pill-shape seragam pada semua elemen, tidak ada glow berlebihan.
- Username default header: `dikzzz`, avatar huruf inisial `D`.
- 5 Anime di Carousel:
  1. *Tokyo Revengers Season 4* (Action/Delinquent, Rating ~7.8, Rilis 2025)
  2. *Black Clover Season 2* (Action/Fantasy/Magic, Rating ~8.0, Rilis 2025)
  3. *Chii Fuyo* (*Tsuihou Sareta Cheat Fuyo Majutsushi*, Rating ~7.6, Rilis 2025)
  4. *Hotaru no Yomeiri* (*Firefly Wedding*, Rating ~8.2, Rilis 2025)
  5. *Tsuihou sareta Tensei juukishi wa game chishiki de musou suru* (Rating ~7.7, Rilis 2025)
- Pesan Continue Watching: Tepat *"Tidak ada riwayat tonton saat ini."*
- 5 Tab Menu: Home, Explore, Jadwal, My list, Profile.

## Review Focus
- Kegagalan memuat gambar jaringan: Carousel harus menampilkan fallback poster placeholder elegan bertema obsidian jika network image gagal atau offline.
- Overflow pada layar kecil: Carousel dan teks metadata harus fleksibel dengan `SingleChildScrollView` atau scroll view aman tanpa RenderFlex overflow.
- Kontras warna teks: Teks sekunder (genre, rating) harus memenuhi standar WCAG AA (kontras minimal 4.5:1 terhadap background `#0B0D13` dan `#141824`).
- Ketepatan inisial avatar: Nama pengguna harus menghasilkan inisial huruf kapital pertama yang tepat (misal `dikzzz` -> `D`).
- Responsivitas Bottom Nav: Perpindahan tab interaktif dan tidak crash saat tab selain Home dipilih.

---

### Task 1: Project Scaffolding & Design System Tokens

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/theme/app_typography.dart`
- Create: `lib/core/theme/app_theme.dart`
- Test: `test/core/theme_test.dart`

**Interfaces:**
- Produces:
  - `class AppColors`: `bgPrimary`, `surfaceCard`, `surfaceElevated`, `borderSubtle`, `accentCrimson`, `accentAmber`, `textPrimary`, `textSecondary`, `textMuted`.
  - `class AppTypography`: `headlineMedium`, `titleLarge`, `titleMedium`, `bodyMedium`, `bodySmall`, `labelSmall`.
  - `ThemeData AppTheme.darkTheme`: Configured dark theme for Flutter.

- [ ] **Step 1: Write the failing test for theme tokens**
Create `test/core/theme_test.dart` asserting `AppColors.bgPrimary == Color(0xFF0B0D13)` and `AppColors.accentCrimson == Color(0xFFE50914)`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/theme_test.dart`
Expected: FAIL (files not found or compile error).

- [ ] **Step 3: Initialize Flutter project & implement Design Tokens**
Create `pubspec.yaml`, `lib/core/theme/app_colors.dart`, `lib/core/theme/app_typography.dart`, and `lib/core/theme/app_theme.dart`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/theme_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
Initialize git and commit: `git add . && git commit -m "feat: setup project scaffolding and obsidian-crimson design tokens"`

---

### Task 2: Data Model & Mock Anime Catalog

**Files:**
- Create: `lib/data/models/anime_item.dart`
- Create: `lib/data/mock/mock_anime_data.dart`
- Test: `test/data/anime_data_test.dart`

**Interfaces:**
- Consumes: Nothing
- Produces:
  - `class AnimeItem`: `id`, `title`, `japaneseTitle`, `rating`, `releaseYear`, `genres`, `description`, `posterUrl`, `backdropUrl`.
  - `List<AnimeItem> mockPopularAnime`: Exactly 5 anime with accurate data (Tokyo Revengers S4, Black Clover S2, Chii Fuyo, Hotaru no Yomeiri, Tsuihou sareta Tensei juukishi).

- [ ] **Step 1: Write the failing test for mock anime catalog**
Create `test/data/anime_data_test.dart` asserting catalog length is 5, contains Tokyo Revengers, Black Clover, Chii Fuyo, Hotaru no Yomeiri, and Tsuihou Sareta Tensei Juukishi with rating > 0.0.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/data/anime_data_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `AnimeItem` and `mockPopularAnime`**
Implement data class and the 5 anime records with verified ratings and high-resolution posters in `lib/data/models/anime_item.dart` and `lib/data/mock/mock_anime_data.dart`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/data/anime_data_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
`git add lib/data test/data && git commit -m "feat: add anime item model and accurate hot popular dataset"`

---

### Task 3: Home Header Widget

**Files:**
- Create: `lib/presentation/widgets/home_header.dart`
- Test: `test/presentation/widgets/home_header_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`.
- Produces: `class HomeHeader extends StatelessWidget` with properties `final String username`, `final VoidCallback? onNotificationTap`, `final VoidCallback? onProfileTap`.

- [ ] **Step 1: Write widget test for HomeHeader**
Create `test/presentation/widgets/home_header_test.dart` verifying username text (`dikzzz`), notification icon (`Icons.notifications_outlined`), and initial avatar letter (`D`).

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/home_header_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `HomeHeader`**
Implement widget with user greeting/name on left, notification bell with subtle badge dot on right, and circular initial avatar on rightmost edge with crimson/slate border.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/home_header_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
`git add lib/presentation/widgets/home_header.dart test/presentation/widgets/home_header_test.dart && git commit -m "feat: implement home header widget"`

---

### Task 4: Spotlight Carousel Widget

**Files:**
- Create: `lib/presentation/widgets/spotlight_carousel.dart`
- Test: `test/presentation/widgets/spotlight_carousel_test.dart`

**Interfaces:**
- Consumes: `AnimeItem`, `AppColors`, `AppTypography`.
- Produces: `class SpotlightCarousel extends StatefulWidget` with property `final List<AnimeItem> items`.

- [ ] **Step 1: Write widget test for SpotlightCarousel**
Create `test/presentation/widgets/spotlight_carousel_test.dart` verifying rendering of first anime title, rating, "Tonton Sekarang" button, and "+" bookmark button.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/spotlight_carousel_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `SpotlightCarousel`**
Implement interactive PageView with auto-height layout, gradient scrim for text readability (anti-slop: subtle dark vignette, no washed out neon), rating badge with amber star, year, genres tag, crimson CTA "Tonton Sekarang", secondary "+" action, and dot indicator.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/spotlight_carousel_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
`git add lib/presentation/widgets/spotlight_carousel.dart test/presentation/widgets/spotlight_carousel_test.dart && git commit -m "feat: implement spotlight carousel with anime metadata and actions"`

---

### Task 5: Empty State Continue Watching Section

**Files:**
- Create: `lib/presentation/widgets/empty_continue_watching.dart`
- Test: `test/presentation/widgets/empty_continue_watching_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`.
- Produces: `class EmptyContinueWatching extends StatelessWidget`.

- [ ] **Step 1: Write widget test for EmptyContinueWatching**
Create `test/presentation/widgets/empty_continue_watching_test.dart` verifying presence of section title "Continue Watching" (or "Lanjutkan Menonton") and exact text "Tidak ada riwayat tonton saat ini."

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/empty_continue_watching_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `EmptyContinueWatching`**
Design an elegant empty card with obsidian surface (`surfaceCard`), subtle border, cinema icon badge, and the exact Indonesian empty message.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/empty_continue_watching_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
`git add lib/presentation/widgets/empty_continue_watching.dart test/presentation/widgets/empty_continue_watching_test.dart && git commit -m "feat: implement empty continue watching section"`

---

### Task 6: Custom Bottom Navigation Bar

**Files:**
- Create: `lib/presentation/widgets/custom_bottom_nav.dart`
- Test: `test/presentation/widgets/custom_bottom_nav_test.dart`

**Interfaces:**
- Consumes: `AppColors`.
- Produces: `class CustomBottomNavBar extends StatelessWidget` with properties `final int currentIndex`, `final ValueChanged<int> onTap`.

- [ ] **Step 1: Write widget test for CustomBottomNavBar**
Create `test/presentation/widgets/custom_bottom_nav_test.dart` checking 5 items: Home, Explore, Jadwal, My list, Profile, and callback firing on tap.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/widgets/custom_bottom_nav_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement `CustomBottomNavBar`**
Implement sleek obsidian navbar with top border 1px, active crimson highlight, and icons matching the requested tab items.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/presentation/widgets/custom_bottom_nav_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**
`git add lib/presentation/widgets/custom_bottom_nav.dart test/presentation/widgets/custom_bottom_nav_test.dart && git commit -m "feat: implement custom bottom navigation bar"`

---

### Task 7: HomeScreen Assembly & Full App Verification

**Files:**
- Create: `lib/presentation/screens/home_screen.dart`
- Create: `lib/main.dart`
- Test: `test/presentation/screens/home_screen_test.dart`
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: All components from Tasks 1-6.
- Produces: Full runnable Flutter application.

- [ ] **Step 1: Write integration widget test for HomeScreen**
Create `test/presentation/screens/home_screen_test.dart` testing the complete home page: renders header with `dikzzz` and `D`, renders popular carousel with Tokyo Revengers, renders "Tidak ada riwayat tonton saat ini.", and renders navigation bar.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/presentation/screens/home_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Assemble `HomeScreen` and entry point `main.dart`**
Compose `HomeScreen` with `SingleChildScrollView`, integrate safe area, header, carousel, continue watching section, and bottom navigation.

- [ ] **Step 4: Run all test suites across the project**
Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 5: Final Commit**
`git add . && git commit -m "feat: integrate full nimeva home screen layout"`

