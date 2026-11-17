# Nimeva Explore Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Membangun halaman Explore/Jelajah dengan tema Modern Monochrome OLED & Electric Azure Blue, dilengkapi kolom pencarian, tab filter dinamis (Popular, Latest, Top Rated), kategori genre, dan grid 2 kolom (6 anime) yang responsif dan terintegrasi dengan Bottom Navigation.

**Architecture:** Memanfaatkan model `AnimeItem` yang diperluas dengan metadata episode/status, mock catalog terindeks per filter/genre, widget modular `AnimeGridCard`, dan `ExploreScreen` dengan reactive state yang terhubung ke bottom navigation.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, Material 3, flutter_test.

**Spec:** Modern Monochrome OLED (#000000, #121212, #1C1C1E, #26262A, #0066FF, #FFB800, #FFFFFF, #A1A1AA).

## Global Constraints
- Tema visual: Modern Monochrome OLED (#000000 Jet Black, #0066FF Azure Blue CTA/indikator).
- Bebas AI slop: tidak ada gradasi ungu/neon, tidak ada border-radius seragam pada semua elemen.
- Grid 2 kolom dengan 6 anime per filter/kategori.
- Setiap anime menampilkan sampul, rating bintang, judul, dan status/episode (misal: "EP 12 · Sub Indo").
- Mengklik tab atau kategori mengubah 6 anime yang ditampilkan secara dinamis.
- Terintegrasi dengan tab Explore di bottom navigation bar.

## Review Focus
- Overflow pada layar kecil: GridView dan text judul harus ter-wrap atau ellipsis tanpa RenderFlex overflow.
- State reactivity: Mengklik tab filter atau genre pill harus segera me-render ulang grid dengan 6 anime yang tepat.
- Offline image safety: Gambar poster harus memiliki placeholder gelap yang elegan jika gagal memuat.

---

### Task 1: Explore Anime Data & Catalog Extension

**Files:**
- Create: `lib/data/mock/mock_explore_data.dart`
- Modify: `lib/data/models/anime_item.dart` (tambahkan field opsional `episodeInfo` dan `statusLabel`)
- Test: `test/data/explore_data_test.dart`

**Interfaces:**
- Produces:
  - `Map<String, List<AnimeItem>> mockExploreCatalog`: Berisi list 6 anime untuk kategori/tab: 'popular', 'latest', 'top_rated', 'action', 'fantasy', 'romance', 'scifi', 'isekai'.
  - `List<AnimeItem> getExploreAnime({required String filter, String? genre})`: Helper function untuk mengambil 6 anime berdasarkan filter aktif.

- [x] **Step 1: Write failing test in `test/data/explore_data_test.dart`**
- [x] **Step 2: Run test to verify it fails (`flutter test test/data/explore_data_test.dart`)**
- [x] **Step 3: Update `AnimeItem` and implement `mock_explore_data.dart`**
- [x] **Step 4: Run test to verify it passes (`flutter test test/data/explore_data_test.dart`)**
- [x] **Step 5: Commit**

---

### Task 2: Anime Grid Card Widget

**Files:**
- Create: `lib/presentation/widgets/anime_grid_card.dart`
- Test: `test/presentation/widgets/anime_grid_card_test.dart`

**Interfaces:**
- Produces:
  - `class AnimeGridCard extends StatelessWidget`: Menerima `AnimeItem item` dan `VoidCallback? onTap`. Menampilkan poster rasio 2:3, badge rating amber, judul tebal putih, dan subtext episode.

- [x] **Step 1: Write failing widget test in `test/presentation/widgets/anime_grid_card_test.dart`**
- [x] **Step 2: Run test to verify it fails (`flutter test test/presentation/widgets/anime_grid_card_test.dart`)**
- [x] **Step 3: Implement `lib/presentation/widgets/anime_grid_card.dart`**
- [x] **Step 4: Run test to verify it passes (`flutter test test/presentation/widgets/anime_grid_card_test.dart`)**
- [x] **Step 5: Commit**

---

### Task 3: Explore Screen with Dynamic Tabs & 2-Column Grid

**Files:**
- Create: `lib/presentation/screens/explore_screen.dart`
- Test: `test/presentation/screens/explore_screen_test.dart`

**Interfaces:**
- Produces:
  - `class ExploreScreen extends StatefulWidget`: Menampilkan header, search input, filter pills (Popular, Latest, Top rated), horizontal genre chips (Semua, Action, Fantasy, Romance, Sci-Fi, Isekai), dan 2-column grid berisi 6 anime.

- [x] **Step 1: Write failing widget test in `test/presentation/screens/explore_screen_test.dart`**
- [x] **Step 2: Run test to verify it fails (`flutter test test/presentation/screens/explore_screen_test.dart`)**
- [x] **Step 3: Implement `lib/presentation/screens/explore_screen.dart`**
- [x] **Step 4: Run test to verify it passes (`flutter test test/presentation/screens/explore_screen_test.dart`)**
- [x] **Step 5: Commit**

---

### Task 4: Navigation Integration in Bottom Navigation & Main App

**Files:**
- Modify: `lib/presentation/screens/home_screen.dart` (hubungkan tab 0 = Home, tab 1 = Explore)
- Test: `test/presentation/screens/home_screen_test.dart`

**Interfaces:**
- Consumes: `HomeScreen`, `ExploreScreen`, `CustomBottomNavBar`.
- Behavior: Tapping tab "Explore" pada bottom nav beralih menampilkan `ExploreScreen`.

- [x] **Step 1: Write failing test in `test/presentation/screens/home_screen_test.dart` verifying tab switching to ExploreScreen**
- [x] **Step 2: Run test to verify it fails**
- [x] **Step 3: Update `HomeScreen` to switch between Home content and `ExploreScreen`**
- [x] **Step 4: Run all tests in the project (`flutter test`)**
- [x] **Step 5: Run `flutter analyze`**
- [x] **Step 6: Commit and finalize**

