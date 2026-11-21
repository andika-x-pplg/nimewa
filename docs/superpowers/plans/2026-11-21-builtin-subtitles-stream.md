# Built-In Subtitles Stream & Japanese Audio Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure all anime titles available in Nimeva with genuine Japanese audio streams featuring built-in Indonesian subtitles (`Sub Indo`) or English subtitles (`Eng Sub`), eliminating foreign dubs (German, Spanish, Portuguese) and resolving accurate episodes.

**Architecture:**
- Stream configurations in `OwnerVideoRepository` and `AnimeStreamResolver` map directly to verified Japanese audio media streams with hardsubbed or container-embedded Sub Indo / Eng Sub tracks.
- `StreamFilterValidator` enforces rejection of foreign audio tracks (German, Spanish Claro dubs, etc.) and enforces Sub Indo / Eng Sub criteria.
- Unit and integration tests verify URL resolutions for all canonical titles, seasons, and movies.

**Tech Stack:** Dart, Flutter, Unit Testing (`flutter test`), Static Analysis (`flutter analyze`).

**Spec:** `docs/superpowers/specs/2026-11-21-builtin-subtitles-stream-design.md`

## Global Constraints

- **Audio Dubbing:** All streams must use original Japanese dubbing (`ja` / `jpn`). No German, Spanish, Portuguese, French, or other foreign audio dubs.
- **Subtitle Priority:** Built-in Indonesian subtitles (`Sub Indo`) primary; if unavailable, English subtitles (`Eng Sub`) fallback.
- **Sequential Integrity:** TV series must resolve strictly sequential episodes 1..N of that specific season. Movies must resolve feature-length films.
- **Test Integrity:** All 166 existing tests must continue passing (100% green); `flutter analyze` must report 0 issues.

## Review Focus

1. *German/Spanish audio leaks*: Streams with German filenames (`Der Stärkste`, `Grausamkeit`, `Flammensäule`) or Claro Video Spanish dubs (`[1st Dubbing]`) must be completely replaced with Japanese audio streams.
2. *Season mismatch*: Season 2 requests (e.g. One Punch Man S2, Tokyo Revengers S2, Demon Slayer S2) must never return Season 1 episodes.
3. *Broken video URL templates*: Multi-episode templates with `{EP}`, `{EP3}`, `{EP_NUM}` must interpolate correctly to valid zero-padded episode URLs.
4. *Server mirrors*: Multi-server URLs (`server1`, `server3` CORS, `server4` Cloud) must resolve cleanly without 404 or dead hosts.
5. *Atomicity principle*: Any incomplete anime without verified authentic episodes must be rejected cleanly rather than playing wrong video.

---

## Tasks

### Task 1: Update OwnerVideoRepository Stream Mappings for Sub Indo / Eng Sub with Japanese Audio

**Files:**
- Modify: `lib/data/services/owner_video_repository.dart`
- Test: `test/data/owner_video_repository_test.dart`

- [x] Write failing unit test in `test/data/owner_video_repository_test.dart` checking that One Punch Man S1 and S2 resolve to Japanese audio with Sub Indo / Eng Sub streams instead of German dubs.
- [x] Run `flutter test test/data/owner_video_repository_test.dart` to confirm failure.
- [x] Update `OwnerVideoRepository` default registrations:
  - Replace One Punch Man S1 files (`_opmS1Files`) with genuine Japanese audio streams (`opm-s1/OPM-BD-{EP}.mp4`).
  - Replace One Punch Man S2 files (`_opmS2Files`) with genuine Japanese audio streams (`opm-s2/O-S2-BD-{EP}.mp4`).
  - Replace Demon Slayer S1, S2, S3 streams with Japanese audio Sub Indo / Eng Sub streams.
  - Replace Spy x Family S1 streams with Japanese audio Sub Indo / Eng Sub streams.
  - Replace Fullmetal Alchemist Brotherhood Claro Video Spanish pack with Japanese audio Sub Indo / Eng Sub streams (`fullmetal-alchemist-brotherhood-1080p...`).
  - Replace Attack on Titan S1 Spanish "Cap" streams with Japanese audio Eng Sub streams (`aot-s-1`).
  - Update `ensureVideosForAnime` keyword mapping for dynamic additions.
- [x] Run `flutter test test/data/owner_video_repository_test.dart` to verify all tests pass.

---

### Task 2: Update AnimeStreamResolver Canonical Mappings

**Files:**
- Modify: `lib/data/services/anime_stream_resolver.dart`
- Test: `test/data/anime_stream_resolver_test.dart`

- [x] Write failing test in `test/data/anime_stream_resolver_test.dart` checking that canonical keys (`one-punch-man`, `one-punch-man-s2`, `demon-slayer`, `attack-on-titan`, `spy-x-family`, `fullmetal-alchemist`) resolve to genuine Japanese audio Sub Indo / Eng Sub streams.
- [x] Run `flutter test test/data/anime_stream_resolver_test.dart` to confirm failure.
- [x] Update `_buildOnePunchManS1()`, `_buildOnePunchManS2()`, `_buildKnySeason1()`, `_buildKnySeason2()`, `_buildKnySeason3()`, `_buildKnySeason4()`, `_buildAotSeason1()`, `_buildSpyFamilySeason1()`, `_buildFmab()`, `_buildBleach()`, and other builders in `lib/data/services/anime_stream_resolver.dart`.
- [x] Run `flutter test test/data/anime_stream_resolver_test.dart` to verify all tests pass.

---

### Task 3: Strengthen StreamFilterValidator

**Files:**
- Modify: `lib/data/services/stream_filter_validator.dart`
- Test: `test/data/stream_filter_validator_test.dart`

- [x] Write test cases in `test/data/stream_filter_validator_test.dart` verifying that foreign dub signatures (e.g., `1st dubbing`, `latino`, `deutsch`, `der stärkste`, `grausamkeit`) are rejected, while Japanese audio with Sub Indo / Eng Sub is accepted.
- [x] Run `flutter test test/data/stream_filter_validator_test.dart` to confirm test behavior.
- [x] Update `StreamFilterValidator` with strict rejection patterns for foreign dubbed streams.
- [x] Re-run `test/data/stream_filter_validator_test.dart` to ensure green.

---

### Task 4: Full Suite Verification & Regression Testing

**Files:**
- Whole codebase

- [x] Run `flutter analyze` to verify 0 errors, 0 warnings.
- [x] Run full test suite: `flutter test`.
- [x] Confirm 100% test pass rate with 0 regressions.

