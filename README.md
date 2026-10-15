# Match 3 - Free Open Source Offline Puzzle Game

Fork of [sidhant947/match3](https://github.com/sidhant947/match3). An elegant, minimal, and open-source Match-3 puzzle game built using Flutter.

[![AI-DECLARATION: copilot](https://img.shields.io/badge/䷼%20AI--DECLARATION-copilot-fee2e2?labelColor=fee2e2)](AI-DECLARATION.md)

## Fork Changes

- **Best-move hints**: the hint simulates every legal swap (or twist) through matches, specials, explosions, obstacles and cascades, and highlights the one that does the most for the current level goal. Moves that complete the goal win outright; then goal progress, then points, specials created and obstacles hit. Refill tiles are unknown, so only deterministic cascades count.
- **Frozen tiles and crates** can no longer be swapped, matching the hint and twist rules.
- **Releases**: every push to `main` publishes a full GitHub release `v<pubspec version>.<run number>` with universal and per-ABI APKs.
- **Dependencies**: Riverpod 3 (legacy providers), `hive_ce` instead of the unmaintained `hive`.
- `scripts/export.sh` dumps all text sources to `docs/llm/dump.txt` for LLM context.

## Toolchain

Flutter 3.47 stable (Dart 3.13), AGP 9.4, Gradle 9.8, Kotlin 2.4, JDK 25. Min Android 7.0 (API 24). No Play Store target.

## Features & Key Perks

- **100% Privacy Focused**: No user data collection, no telemetry, and no registration required.
- **Zero Ads**: Play with no commercial interruptions or pop-ups.
- **No Trackers**: Completely free of analytics, advertising IDs, or third-party trackers.
- **Completely Offline**: Fully functional offline. Ideal for commutes, travel, or areas with low connectivity.
- **Infinite Levels**: Endless puzzle challenges with procedurally generated configurations.

## Release Secrets

`KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`.

## License

Licensed under the GNU General Public License v3.0 (GPL-3.0).
