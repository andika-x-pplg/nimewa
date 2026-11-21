# Built-In Subtitles Stream & Japanese Audio Specification

**Date:** 2026-11-21  
**Status:** Approved  
**Author:** Antigravity Team  

---

## 1. Goal

Ensure all anime with video streams in the Nimeva application are configured with video URLs featuring:
1. **Built-in Subtitles**: Prioritize Indonesian subtitles (`Sub Indo`). If Indonesian subtitles are unavailable for that title, provide English subtitles (`Eng Sub`). Subtitles are either hardsubbed directly into the video stream or embedded as default subtitle tracks in standard MP4/MKV containers.
2. **Authentic Japanese Audio**: Strictly use the original Japanese dubbing (Japanese voice cast). Foreign language dubs (such as German, Spanish, Portuguese, French, Hindi) are strictly prohibited.
3. **Accurate Canonical Matching**: Episode 1 through N must strictly match the anime title, season, and chronological progression. Movies must be mapped to feature-length videos, not TV episodes, and TV series episodes must not map to movies.

---

## 2. Core Principles & Constraints

### 2.1 Subtitle Hierarchy
- **Tier 1 (Preferred)**: Built-in Indonesian Subtitles (`Sub Indo` / Indonesian fansub / multi-sub track).
- **Tier 2 (Fallback)**: Built-in English Subtitles (`Eng Sub` / HorribleSubs / SubsPlease / Judas / Hi10 / Erai-raws / multi-sub track).
- **Forbidden**: Raw video with no subtitles, or video with foreign non-English/non-Indonesian subtitles.

### 2.2 Audio Dubbing Constraint
- **Allowed**: Japanese original voice acting (`ja` / `jpn`).
- **Forbidden**: Non-Japanese audio dubs (e.g., German dubs like "Der Stärkste" / "Entrückter Cyborg", Spanish dubs from Claro packs, Portuguese dubs).

### 2.3 Season & Episode Canonical Integrity
- AniList ID and season number must match exactly.
- No cross-season fallback (e.g., Season 2 cannot fall back to Season 1).
- All mapped episodes must be complete and playable.

---

## 3. Scope of Affected Anime Catalog

The following anime catalog entries in `OwnerVideoRepository` and `AnimeStreamResolver` must be verified and updated to Japanese audio with Sub Indo / Eng Sub:

| # | Anime Title | AniList ID | Season / Type | Target Audio / Subtitle |
|---|-------------|------------|---------------|-------------------------|
| 1 | One Punch Man | 21087 | Season 1 (12 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 2 | One Punch Man S2 | 102194 / 97668 | Season 2 (12 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 3 | Demon Slayer (Kimetsu no Yaiba) S1 | 101922 | Season 1 (26 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 4 | Demon Slayer S2 (Entertainment District) | 142329 | Season 2 (11 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 5 | Demon Slayer S3 (Swordsmith Village) | 145139 | Season 3 (11 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 6 | Demon Slayer S4 (Hashira Training) | - | Season 4 (8 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 7 | Demon Slayer Movie (Mugen Train) | - | Movie (1 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 8 | Solo Leveling | 151807 | Season 1 (12 Ep) | Japanese Audio, Multi-Sub (Eng/Indo) |
| 9 | Attack on Titan (Shingeki no Kyojin) | 16498 | Season 1 (25 Ep) | Japanese Audio, Eng Sub / Sub Indo |
| 10 | Jujutsu Kaisen S1 | 113415 | Season 1 (24 Ep) | Japanese Audio, Eng Sub (KaNNa) |
| 11 | Jujutsu Kaisen 0 | - | Movie (1 Ep) | Japanese Audio, Eng Sub |
| 12 | Tokyo Revengers S1 | 120120 | Season 1 (24 Ep) | Japanese Audio, Eng Sub |
| 13 | Tokyo Revengers S2 | 142853 | Season 2 (13 Ep) | Japanese Audio, Eng Sub |
| 14 | Tokyo Revengers S3 | 163539 | Season 3 (13 Ep) | Japanese Audio, Sub Indo / Eng Sub |
| 15 | Tokyo Revengers S4 | 178945 | Season 4 (1 Ep) | Japanese Audio, Eng Sub |
| 16 | Chainsaw Man S1 | 127720 | Season 1 (12 Ep) | Japanese Audio, Eng Sub (Hi10/GJM) |
| 17 | Dandadan | 166240 | Season 1 (12 Ep) | Japanese Audio, Multi-Sub |
| 18 | Spy x Family | 140960 | Season 1 (12 Ep) | Japanese Audio, Eng Sub / Sub Indo |
| 19 | Death Note | 1535 | Season 1 (37 Ep) | Japanese Audio, Eng Sub |
| 20 | Naruto | 20 | Season 1 (220 Ep) | Japanese Audio, Eng Sub / Sub Indo |
| 21 | Bleach | 269 | Season 1 (366 Ep) | Japanese Audio, Eng Sub |
| 22 | Fullmetal Alchemist: Brotherhood | 5114 | Season 1 (64 Ep) | Japanese Audio, Eng Sub / Sub Indo |
| 23 | Steins;Gate | 9253 | Season 1 (24 Ep) | Japanese Audio, Eng Sub (Anime Time) |
| 24 | Sousou no Frieren | 154587 | Season 1 (28 Ep) | Japanese Audio, Eng Sub (AnimePahe) |
| 25 | Shigatsu wa Kimi no Uso | 20665 | Season 1 (22 Ep) | Japanese Audio, Eng Sub |
| 26 | Koe no Katachi (A Silent Voice) | 20954 | Movie (1 Ep) | Japanese Audio, Eng Sub |
| 27 | Kimi no Na wa (Your Name) | 21827 | Movie (1 Ep) | Japanese Audio, Eng Sub |
| 28 | Tokyo Ghoul S1 | 20605 | Season 1 (12 Ep) | Japanese Audio, Eng Sub |
| 29 | Yosuga no Sora | 8861 | Season 1 (12 Ep) | Japanese Audio, Eng Sub (YURASUKA) |

---

## 4. Verification Plan
- Unit tests covering `OwnerVideoRepository` ensure all registered streams are Japanese audio and feature Sub Indo or Eng Sub.
- Unit tests in `AnimeStreamResolverTest` verify all canonical anime keys resolve to Japanese audio with Sub Indo / Eng Sub streams.
- Full test suite (`flutter test`) passes 100%.
- Static analysis (`flutter analyze`) reports 0 warnings/errors.

