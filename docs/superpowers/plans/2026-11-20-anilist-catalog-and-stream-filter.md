# AniList GraphQL Catalog & Stream Filter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade Nimeva with an AniList GraphQL catalog, franchise prequel/sequel relations, robust image placeholders, strict video stream filtering (blocking reactions/reviews), AniList ID season matching without fallback, and structured stream audit logging.

**Architecture:** 
1. `AniListApiClient` executes GraphQL POST queries to `https://graphql.anilist.co` for trending, explore, search, and detail with relationships.
2. `StreamFilterValidator` rejects reaction/review/recap/untrusted video streams.
3. `StreamAuditLogger` logs search query, candidate title, acceptance verdict, and reason.
4. `AnimeStreamResolver` matches streams strictly by AniList ID and omits unplayable episodes without cross-season fallback.
5. Presentation layer displays all AniList anime with availability badges (`Tersedia Video` vs `Belum Ada Video`), prequel/sequel relation cards, and `AnimeImagePlaceholder` for missing images.

**Tech Stack:** Flutter / Dart, GraphQL HTTP client, Modern Monochrome OLED & Azure Blue design system, `flutter_test`.

**Spec:** [design_doc.md](file:///C:/Users/Administrator/.gemini/antigravity/brain/229aafc4-8b5f-49b2-a7f8-7a363b91d9bc/design_doc.md)

## Global Constraints
- Target AniList GraphQL endpoint: `https://graphql.anilist.co`.
- Video availability badge states: `"Tersedia Video"` (accent blue) and `"Belum Tersedia"` (neutral grey).
- Forbidden video regex terms: `reaction`, `react`, `review`, `reaksi`, `nonton bareng`, `nobar`, `explain`, `explained`, `teori`, `theory`, `discussion`, `trailer`, `teaser`, `clip`, `amv`, `edit`, `recap`.
- Never fallback to another season when an episode is missing; hide the episode.
- Never hide an anime from the catalog merely because it lacks video streams.
- Zero issues on `flutter analyze`.

## Review Focus
1. Empty or broken image URLs in AniList: Must render `AnimeImagePlaceholder` with clean anime title without throwing exceptions or leaving blank white space.
2. Season ID routing: AniList ID for sequels (e.g. Tokyo Revengers S4) must not resolve to S1/S2/S3 episodes; must cleanly mark `hasVideoAvailable = false` when streams do not exist.
3. Stream filter validator: Videos titled "Tokyo Revengers Reaction Episode 1" or "Attack on Titan Review" must be rejected with explicit audit log reason recorded.
4. Prequel/Sequel relations: Anime detail screen must display relation cards that navigate to the respective related anime.
5. Offline / API timeout resilience: If network times out, client falls back gracefully to curated offline AniList-structured data without crashing.

---

### Task 1: Extended Models & AniList GraphQL Client

**Files:**
- Create: `lib/data/models/anime_relation_item.dart`
- Modify: `lib/data/models/anime_item.dart`
- Modify: `lib/data/models/anime_detail.dart`
- Create: `lib/data/services/anilist_api_client.dart`
- Test: `test/data/anilist_api_client_test.dart`

- [ ] **Step 1: Write failing tests for `AnimeRelationItem`, extended `AnimeItem`, and `AniListApiClient`**
  - Verify JSON parsing of AniList GraphQL response format:
    - Romaji, English, Native titles
    - `coverImage.large`, `coverImage.extraLarge`, `bannerImage`
    - `relations.edges[].relationType` and `node`
    - `hasVideoAvailable` flag computation
  - File: `test/data/anilist_api_client_test.dart`

- [ ] **Step 2: Run test to confirm it fails**
  - Run `flutter test test/data/anilist_api_client_test.dart`

- [ ] **Step 3: Implement `AnimeRelationItem`, update `AnimeItem` and `AnimeDetail`**
  - Add `aniListId` (int), `hasVideoAvailable` (bool), and `bannerUrl` (String?) to `AnimeItem`.
  - Add `aniListId` (int), `relations` (List<AnimeRelationItem>), and `hasVideoAvailable` (bool) to `AnimeDetail`.
  - Files: `lib/data/models/anime_relation_item.dart`, `lib/data/models/anime_item.dart`, `lib/data/models/anime_detail.dart`.

- [ ] **Step 4: Implement `AniListApiClient`**
  - Build GraphQL query strings for trending, explore, search, and detail with relationships.
  - Parse AniList Media objects into `AnimeItem` and `AnimeDetail`.
  - Include resilient offline fallback data using verified AniList IDs.
  - File: `lib/data/services/anilist_api_client.dart`.

- [ ] **Step 5: Run tests and verify they pass**
  - Run `flutter test test/data/anilist_api_client_test.dart`

- [ ] **Step 6: Commit Task 1**
  - `git add -A; git commit -m "feat(data): add AniList GraphQL client and franchise relation models"`

---

### Task 2: Stream Filter Validator & Stream Audit Logger

**Files:**
- Create: `lib/data/services/stream_filter_validator.dart`
- Create: `lib/data/services/stream_audit_logger.dart`
- Test: `test/data/stream_filter_validator_test.dart`
- Test: `test/data/stream_audit_logger_test.dart`

- [ ] **Step 1: Write failing tests for `StreamFilterValidator` and `StreamAuditLogger`**
  - Test validator against:
    - Valid episode titles: "Episode 1 Sub Indo", "Tokyo Revengers S01E01" -> ACCEPTED
    - Reaction titles: "Demon Slayer Episode 1 Reaction!", "Reaksi Nonton Anime Ep 1" -> REJECTED (Reason: Contains reaction/reaksi)
    - Review/Theory/Explain titles: "Attack on Titan Ending Explained", "Jujutsu Kaisen Review" -> REJECTED (Reason: Contains review/explain)
    - Nobar titles: "Nobar Dandadan bareng teman" -> REJECTED (Reason: Contains nobar)
    - Untrusted source domain / invalid scheme -> REJECTED
  - Test `StreamAuditLogger`:
    - Adding log entry records timestamp, searchedTitle, candidateTitle, verdict, and reason.
    - Exposing `recentLogs` and `clearLogs()`.

- [ ] **Step 2: Run tests to confirm failure**
  - Run `flutter test test/data/stream_filter_validator_test.dart test/data/stream_audit_logger_test.dart`

- [ ] **Step 3: Implement `StreamFilterValidator`**
  - Implement regex blacklist: `reaction`, `react`, `review`, `reaksi`, `nonton bareng`, `nobar`, `explain`, `explained`, `teori`, `theory`, `discussion`, `trailer`, `teaser`, `clip`, `amv`, `edit`, `recap`.
  - Verify official/whitelisted stream URLs.
  - Return `StreamValidationResult(isValid, reason)`.

- [ ] **Step 4: Implement `StreamAuditLogger`**
  - Store `StreamAuditLogEntry` instances with memory cap (e.g. 200 logs).
  - Print structured debug lines: `[STREAM_AUDIT] searched="<title>" candidate="<candidate>" status=<ACCEPTED/REJECTED> reason="<reason>"`.

- [ ] **Step 5: Run tests and verify they pass**
  - Run `flutter test test/data/stream_filter_validator_test.dart test/data/stream_audit_logger_test.dart`

- [ ] **Step 6: Commit Task 2**
  - `git add -A; git commit -m "feat(stream): implement StreamFilterValidator and StreamAuditLogger"`

---

### Task 3: AniList ID Season Matching & Episode Omission in Resolver

**Files:**
- Modify: `lib/data/services/anime_stream_resolver.dart`
- Test: `test/data/anime_stream_resolver_test.dart`

- [ ] **Step 1: Write failing tests in `anime_stream_resolver_test.dart`**
  - Test matching by AniList ID:
    - Tokyo Revengers S1 (120120) -> plays authentic S1.
    - Tokyo Revengers S2 (142853) -> plays authentic S2.
    - Tokyo Revengers S3 (163539) -> plays authentic S3.
    - Tokyo Revengers S4 (178945) -> `hasCompleteEpisodes` returns `false`, `resolveStreamUrl` returns empty string, no cross-season fallback.
  - Test filter validator integration: candidates with "reaction" are rejected and logged.
  - Test missing episode behavior: returns empty string.

- [ ] **Step 2: Run test to confirm failure**
  - Run `flutter test test/data/anime_stream_resolver_test.dart`

- [ ] **Step 3: Update `AnimeStreamResolver` with AniList ID map**
  - Add AniList ID mapping table:
    - `120120`: `'tokyo-revengers'`
    - `142853`: `'tokyo-revengers-s2'`
    - `163539`: `'tokyo-revengers-s3'`
    - `178945`: incomplete / no video
    - `38000` / `101922`: `'demon-slayer'`
    - `16498`: `'attack-on-titan'`
    - `1535`: `'death-note'`
    - `113415`: `'jujutsu-kaisen'`
    - `117410`: `'chainsaw-man'`
    - `151807`: `'solo-leveling'`
    - `154587`: `'frieren'`
    - `166240`: `'dandadan'`
  - Integrate `StreamFilterValidator` and `StreamAuditLogger` into stream resolution.
  - Strictly omit episodes that have no valid stream.

- [ ] **Step 4: Run tests and verify they pass**
  - Run `flutter test test/data/anime_stream_resolver_test.dart`

- [ ] **Step 5: Commit Task 3**
  - `git add -A; git commit -m "feat(stream): map streams strictly by AniList ID and log candidate verdicts"`

---

### Task 4: Image Placeholder Widget & Video Availability Badges

**Files:**
- Create: `lib/presentation/widgets/anime_image_placeholder.dart`
- Modify: `lib/presentation/widgets/anime_grid_card.dart`
- Modify: `lib/presentation/widgets/spotlight_carousel.dart`
- Test: `test/presentation/widgets/anime_image_placeholder_test.dart`
- Test: `test/presentation/widgets/anime_grid_card_test.dart`

- [ ] **Step 1: Write failing widget tests**
  - Test `AnimeImagePlaceholder` renders title, subtle movie icon, dark container when URL is empty.
  - Test `AnimeGridCard` displays `"Tersedia Video"` badge when `hasVideoAvailable == true`, and `"Belum Tersedia"` when `false`.
  - Test image error builder falls back to `AnimeImagePlaceholder`.

- [ ] **Step 2: Run tests to confirm failure**
  - Run `flutter test test/presentation/widgets/anime_image_placeholder_test.dart test/presentation/widgets/anime_grid_card_test.dart`

- [ ] **Step 3: Implement `AnimeImagePlaceholder`**
  - Create widget with theme-compliant colors (`#161618` card surface, `borderSubtle`, `accentBlue` subtle icon accent, clear white title).
  - Handles various aspect ratios (poster 2:3 and banner 16:9).

- [ ] **Step 4: Update `AnimeGridCard` and `SpotlightCarousel`**
  - Update `AnimeGridCard` to render `AnimeImagePlaceholder` when `posterUrl.isEmpty` or on `imageBuilder` error.
  - Render availability badge: accent blue for `Tersedia Video`, subtle grey for `Belum Tersedia`.
  - In `SpotlightCarousel`, handle missing banner with placeholder.

- [ ] **Step 5: Run tests and verify they pass**
  - Run `flutter test test/presentation/widgets/anime_image_placeholder_test.dart test/presentation/widgets/anime_grid_card_test.dart test/presentation/widgets/spotlight_carousel_test.dart`

- [ ] **Step 6: Commit Task 4**
  - `git add -A; git commit -m "feat(ui): add AnimeImagePlaceholder and video availability badges"`

---

### Task 5: Franchise Relations Carousel & Service Integration

**Files:**
- Modify: `lib/data/services/anime_stream_service.dart`
- Modify: `lib/presentation/screens/anime_detail_screen.dart`
- Modify: `lib/presentation/screens/home_screen.dart`
- Modify: `lib/presentation/screens/explore_screen.dart`
- Test: `test/presentation/screens/anime_detail_screen_test.dart`
- Test: `test/data/anime_stream_service_test.dart`

- [ ] **Step 1: Write failing tests for service integration and detail screen relations**
  - Test `AnimeStreamService` delegates to `AniListApiClient`.
  - Test `AnimeDetailScreen` renders "Relasi Franchise / Prequel & Sequel" section when relations are present.
  - Test `AnimeDetailScreen` hides unplayable episodes if `hasVideoAvailable` is false or stream is empty, showing a clear notice ("Episode video belum tersedia untuk judul ini").

- [ ] **Step 2: Run tests to confirm failure**
  - Run `flutter test test/presentation/screens/anime_detail_screen_test.dart test/data/anime_stream_service_test.dart`

- [ ] **Step 3: Update `AnimeStreamService` to use `AniListApiClient`**
  - Update `getSpotlightAnime`, `getExploreAnimeList`, and `getAnimeDetail` to utilize `AniListApiClient`.
  - Do NOT filter out anime without videos from the catalog; preserve all AniList entries with accurate `hasVideoAvailable` flags.

- [ ] **Step 4: Update `AnimeDetailScreen`**
  - Add horizontal franchise relations carousel (`Prequel`, `Sequel`, `Side Story`).
  - Tapping a relation card navigates to `AnimeDetailScreen` for that related anime ID.
  - Filter episode list to only show genuine available episodes. If none, show informative card.

- [ ] **Step 5: Run tests and verify they pass**
  - Run `flutter test test/presentation/screens/anime_detail_screen_test.dart test/data/anime_stream_service_test.dart`

- [ ] **Step 6: Commit Task 5**
  - `git add -A; git commit -m "feat(detail): add franchise relation carousel and wire AniList service"`

---

### Task 6: Full Verification & Static Analysis

**Files:**
- All modified and new files.

- [ ] **Step 1: Run `flutter analyze`**
  - Verify 0 errors, 0 warnings across the entire project.

- [ ] **Step 2: Run the full test suite (`flutter test`)**
  - Ensure all unit, widget, and integration tests pass without failures.

- [ ] **Step 3: Final Git Commit**
  - Verify clean working tree with `git status`.

