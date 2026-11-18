# Nimeva Live API Integration & Multi-Server Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace static mock catalogs with a 100% real Live Anime API (10 items in Home Carousel, live dynamic Explore catalog with accurate titles, genuine posters, real ratings, and accurate episode counts), plus multi-server health status and in-player failover notifications in AnimeWatchScreen.

**Architecture:** 
1. Build `AnimeApiClient` using Dart's native `HttpClient` targeting the live Kitsu REST API (`kitsu.io`) with JSON:API headers and resilient cached fallbacks.
2. Hook `AnimeApiClient` into `AnimeStreamService` to supply 10 live trending anime on Home and real dynamic search/categories on Explore.
3. Enhance `AnimeWatchScreen` with server status tracking and in-player alert banner when a server is inactive/maintenance, with a single-tap button to switch to an active server.

**Tech Stack:** Flutter 3.13 / Dart 3.1, `dart:io` (HttpClient), `dart:convert`, Flutter Material 3, Dark Monochrome Palette (#000000, #121212, #0066FF).

**Spec:** User prompt requesting 100% real API integration (10 real anime in Home popular section, live Explore catalog, real episode counts, and functional video playback with server warning notifications).

## Global Constraints
- Modern Monochrome & Electric Azure Blue design system (#000000 background, #121212 cards, #0066FF accent, #FFB800 rating).
- Zero AI-slop: High contrast, readable typography, standard 48x48dp tap targets, and no unstyled spinners.
- Resilient offline/test execution: If network is offline or in widget test environment, gracefully use cached fallback so tests run reliably.

## Review Focus
- Home carousel rendering 10 items without layout overflow.
- Explore search bar dynamically querying live API with debounced/instant updates.
- Real episode count reflection (finished anime shows exact total count, ongoing anime shows latest release).
- Video player server switcher warning when selecting an unavailable server.
- One-tap switch button resolving the error state and switching to Server 1.

---

### Task 1: Create `AnimeApiClient` for Live Kitsu REST API

**Files:**
- Create: `lib/data/services/anime_api_client.dart`
- Test: `test/data/anime_api_client_test.dart`

**Interfaces:**
- Consumes: `HttpClient`, `AnimeItem`, `AnimeDetail`, `EpisodeItem`
- Produces:
  - `Future<List<AnimeItem>> fetchTrendingAnime({int limit = 10})`
  - `Future<List<AnimeItem>> searchAnime(String query, {int limit = 10})`
  - `Future<List<AnimeItem>> fetchAnimeByCategory(String category, {int limit = 10})`
  - `Future<AnimeDetail> fetchAnimeDetail(String id)`

- [ ] **Step 1: Write the failing tests in `test/data/anime_api_client_test.dart`**
- [ ] **Step 2: Run test to verify it fails**
- [ ] **Step 3: Implement `AnimeApiClient` in `lib/data/services/anime_api_client.dart`**
- [ ] **Step 4: Run tests and ensure they pass**
- [ ] **Step 5: Commit changes**

---

### Task 2: Integrate Live API into `AnimeStreamService` and Home Screen

**Files:**
- Modify: `lib/data/services/anime_stream_service.dart`
- Modify: `lib/presentation/screens/home_screen.dart`
- Modify: `lib/presentation/widgets/spotlight_carousel.dart`
- Test: `test/presentation/screens/home_screen_test.dart`
- Test: `test/presentation/widgets/spotlight_carousel_test.dart`

**Interfaces:**
- Consumes: `AnimeApiClient`
- Produces:
  - Home Carousel displays 10 real trending anime from live API
  - Seamless pagination/dot indicator handling for 10 items without overflow

- [ ] **Step 1: Write test verifying Home Carousel loads 10 items from API client**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Update `AnimeStreamService` and `HomeScreen` to fetch 10 items**
- [ ] **Step 4: Run tests to verify pass**
- [ ] **Step 5: Commit changes**

---

### Task 3: Integrate Live API into Explore Screen

**Files:**
- Modify: `lib/presentation/screens/explore_screen.dart`
- Test: `test/presentation/screens/explore_screen_test.dart`

**Interfaces:**
- Consumes: `AnimeStreamService.getExploreAnimeList` with live search and category query
- Produces:
  - Live search against Kitsu API
  - Live category filters (Action, Fantasy, Romance, Sci-Fi)
  - Real episode counts and official posters

- [ ] **Step 1: Write test for live search & category filtering in `explore_screen_test.dart`**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Update `ExploreScreen` to query live API endpoints**
- [ ] **Step 4: Run tests to verify pass**
- [ ] **Step 5: Commit changes**

---

### Task 4: Video Player Multi-Server Reliability & Error Notification UI

**Files:**
- Modify: `lib/presentation/screens/anime_watch_screen.dart`
- Test: `test/presentation/screens/anime_watch_screen_test.dart`

**Interfaces:**
- Consumes: Server status mapping (`Server 1 (Fast HD)`: Active, `Server 2 (Backup)`: Inactive/Maintenance, `Server 3 (Otaku)`: Active)
- Produces:
  - In-player notification banner when unavailable server is selected
  - "Ganti ke Server 1" quick action button that switches server and resumes playback
  - Visual status dots on server selection chips

- [ ] **Step 1: Write test verifying in-player error alert appears on Server 2 selection and resolves when tapping switch**
- [ ] **Step 2: Run test to verify failure**
- [ ] **Step 3: Implement server status checking and error overlay in `AnimeWatchScreen`**
- [ ] **Step 4: Run tests to verify pass**
- [ ] **Step 5: Commit changes**

---

### Task 5: Full Project Verification & Device Testing

**Files:**
- All modified files

- [ ] **Step 1: Run `flutter analyze` to ensure 0 lint errors**
- [ ] **Step 2: Run all `flutter test` suites to verify 100% pass**
- [ ] **Step 3: Build & verify on physical device**
