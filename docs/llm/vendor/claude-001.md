00
22

I have cloned an existing github repository 
and will host my copy at https://github.com/kusl/sidhant947-match3 
the original repository was at https://github.com/sidhant947/match3
I have added repository secrets 
KEYSTORE_BASE64
KEY_ALIAS
KEY_PASSWORD
STORE_PASSWORD

I copied them from an existing working repository so I think it should be right. 
that being said 

I have updated the github actions versions 
and I have added an export.sh 

there are a few things I would like to change 
1. run a full release, not a pre release, a full release with an apk with each push 
the current yaml is broken because I tried to fix it but clearly didn't fix it completely. 
please include full yaml with your response 
2. the export.sh should include all files necessary for you or any LLM 
I added  kt kts gradle properties yaml dart 
but export.sh was originally made for dotnet c sharp so I am sure I must have missed something 
3. this is the most important change and the reason why this fork exists. 
instead of showing any random hint, show the best possible move as the hint 


If only a few files (under five or there about) need to change, give me the full path of the files that need to change and the FULL file 
if there are a lot of files that need to change 
    Delivery
    Whole project as one tar.gz, unambiguous file placement
    Any files to delete on updates called out explicitly
    No bespoke sed/patch scripts — full files only for anything that changes
    Docs updated alongside code changes
    Low verbosity, no code comments
    NEVER EVER EVER write code comments. 
    in fact, never, ever write comments at all. 
    markdown files such as readme.md are the exception but even these should be as concise and terse as possible.





























































/
I have cloned an existing github repository 
and will host my copy at https://github.com/kusl/sidhant947-match3 
the original repository was at https://github.com/sidhant947/match3
I have added repository secrets 
KEYSTORE_BASE64
KEY_ALIAS
KEY_PASSWORD
STORE_PASSWORD

I copied them from an existing working repository so I think it should be right. 
that being said 

I have updated the github actions versions 
and I have added an export.sh 

there are a few things I would like to change 
1. run a full release, not a pre release, a full release with an apk with each push 
the current yaml is broken because I tried to fix it but clearly didn't fix it completely. 
please include full yaml with your response 
2. the export.sh should include all files necessary for you or any LLM 
I added  kt kts gradle properties yaml dart 
but export.sh was originally made for dotnet c sharp so I am sure I must have missed something 
3. this is the most important change and the reason why this fork exists. 
instead of showing any random hint, show the best possible move as the hint 

If only a few files (under five or there about) need to change, give me the full path of the files that need to change and the FULL file 
if there are a lot of files that need to change 
    Delivery
    Whole project as one tar.gz, unambiguous file placement
    Any files to delete on updates called out explicitly
    No bespoke sed/patch scripts — full files only for anything that changes
    Docs updated alongside code changes
    Low verbosity, no code comments
    NEVER EVER EVER write code comments. 
    in fact, never, ever write comments at all. 
    markdown files such as readme.md are the exception but even these should be as concise and terse as possible.

Ran 20 commands, created a file
Five files. Nothing to delete. I couldn’t compile Dart here, so run flutter analyze once before you push.

The workflow broke because tag_name: ${{ inputs.version }} is empty on a push; that input only exists for workflow_dispatch. The new workflow builds the tag itself: v<pubspec version>.<run number>, for example v1.0.10.42. It passes the secrets through env so special characters in passwords don’t break the shell. It also runs keytool to fail early if the keystore, alias or password is wrong.

The hint now simulates every legal swap (or clockwise twist) using the game’s own rules: matches, specials, explosions, ice and crate damage, jelly, and cascades. Refill tiles are random, so they’re treated as unknown and never match; the hint looks one move ahead only. Moves are ranked first by whether they complete the level goal, then by progress toward the goal, then by points, specials created and obstacles hit.

One behaviour change: swapTiles now refuses swaps involving frozen tiles or crates. The original code let you swap them even though canSwap existed and the twist and shuffle code respected it. Without this, the best-move logic wouldn’t match what the game actually allows.

.github/workflows/build.yml
yaml
name: Build and Release

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: write

concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: false

jobs:
  release:
    name: Build and Release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v7

      - name: Setup Java
        uses: actions/setup-java@v6
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Compute Version
        id: version
        run: |
          name="$(sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' pubspec.yaml)"
          test -n "$name"
          code=$((100 + GITHUB_RUN_NUMBER))
          echo "name=$name" >> "$GITHUB_OUTPUT"
          echo "code=$code" >> "$GITHUB_OUTPUT"
          echo "tag=v$name.$GITHUB_RUN_NUMBER" >> "$GITHUB_OUTPUT"

      - name: Get Dependencies
        run: flutter pub get

      - name: Setup Keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
          KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
          STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
        run: |
          for v in KEYSTORE_BASE64 KEY_ALIAS KEY_PASSWORD STORE_PASSWORD; do
            if [ -z "${!v}" ]; then echo "::error::Missing secret $v"; exit 1; fi
          done
          printf '%s' "$KEYSTORE_BASE64" | base64 --decode --ignore-garbage > android/app/upload-keystore.jks
          keytool -list -keystore android/app/upload-keystore.jks -storepass "$STORE_PASSWORD" -alias "$KEY_ALIAS" > /dev/null
          {
            printf 'storePassword=%s\n' "$STORE_PASSWORD"
            printf 'keyPassword=%s\n' "$KEY_PASSWORD"
            printf 'keyAlias=%s\n' "$KEY_ALIAS"
            printf 'storeFile=upload-keystore.jks\n'
          } > android/key.properties

      - name: Build APKs
        run: |
          flutter build apk --release --build-name=${{ steps.version.outputs.name }} --build-number=${{ steps.version.outputs.code }}
          flutter build apk --release --split-per-abi --build-name=${{ steps.version.outputs.name }} --build-number=${{ steps.version.outputs.code }}
          ls -l build/app/outputs/flutter-apk/

      - name: Publish Release
        uses: softprops/action-gh-release@v3
        with:
          tag_name: ${{ steps.version.outputs.tag }}
          name: ${{ steps.version.outputs.tag }}
          target_commitish: ${{ github.sha }}
          draft: false
          prerelease: false
          make_latest: 'true'
          generate_release_notes: true
          fail_on_unmatched_files: true
          files: build/app/outputs/flutter-apk/*.apk
scripts/export.sh
I tested this against a clone of the original repo: it now exports 59 files instead of 45. The newly picked-up files are:

the AndroidManifest.xml files and the res/*.xml files
pubspec.lock
.metadata
the fastlane .txt files
I also dropped the .NET extensions, excluded Flutter build folders, and replaced the .NET SDK header line with the Flutter version.

bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_PATH="${1:-$SCRIPT_DIR/..}"
OUTPUT_FILE="${2:-docs/llm/dump.txt}"

INCLUDE_EXTENSIONS="dart yaml yml kt kts java gradle properties xml json arb lock md txt sh toml pro cfg html css js svg plist swift xcconfig cmake"
INCLUDE_NAMES=".gitignore .gitattributes .editorconfig .metadata"
EXCLUDE_NAMES="LICENSE"
EXCLUDE_DIRS="build .dart_tool .gradle .pub-cache .git .idea .vscode .cxx Pods ephemeral coverage node_modules"
EXCLUDE_PREFIXES="docs/llm/"

PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
cd "$PROJECT_PATH"

case "$OUTPUT_FILE" in
    /*) OUTPUT_PATH="$OUTPUT_FILE" ;;
    *)  OUTPUT_PATH="$PROJECT_PATH/$OUTPUT_FILE" ;;
esac
OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
mkdir -p "$OUTPUT_DIR"

OUTPUT_REL="${OUTPUT_PATH#"$PROJECT_PATH"/}"

if [ -t 1 ]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; CYAN=''; NC=''
fi
log() { printf "%b%s%b\n" "$1" "$2" "$NC"; }

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    else
        printf 'unavailable'
    fi
}

mod_time_utc_of() {
    local epoch
    if epoch="$(stat -c '%Y' "$1" 2>/dev/null)"; then
        date -u -d "@$epoch" '+%Y-%m-%d %H:%M:%S'
    else
        epoch="$(stat -f '%m' "$1")"
        date -u -r "$epoch" '+%Y-%m-%d %H:%M:%S'
    fi
}

line_count_of() {
    awk 'END { print NR }' "$1"
}

is_included_file() {
    local name="${1##*/}" ext entry
    for entry in $EXCLUDE_NAMES; do
        [ "$name" = "$entry" ] && return 1
    done
    case "$name" in
        .env|.env.*) return 1 ;;
    esac
    for entry in $INCLUDE_NAMES; do
        [ "$name" = "$entry" ] && return 0
    done
    ext="${name##*.}"
    [ "$ext" != "$name" ] || return 1
    ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"
    for entry in $INCLUDE_EXTENSIONS; do
        [ "$ext" = "$entry" ] && return 0
    done
    return 1
}

is_excluded_path() {
    local path="$1" entry
    for entry in $EXCLUDE_PREFIXES; do
        case "$path" in
            "$entry"*) return 0 ;;
        esac
    done
    for entry in $EXCLUDE_DIRS; do
        case "$path" in
            "$entry"/*|*/"$entry"/*) return 0 ;;
        esac
    done
    return 1
}

is_text() {
    [ ! -s "$1" ] || grep -Iq . "$1"
}

in_git_repo() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

render_tree() {
    local -a parts prev
    local rel n common i j indent
    prev=()
    echo "."
    while IFS= read -r -d '' rel; do
        IFS='/' read -r -d '' -a parts < <(printf '%s\0' "$rel") || true
        n=${#parts[@]}

        common=0
        while [ "$common" -lt $((n - 1)) ] && [ "$common" -lt "${#prev[@]}" ] \
              && [ "${parts[$common]}" = "${prev[$common]}" ]; do
            common=$((common + 1))
        done

        for ((i = common; i < n; i++)); do
            indent="    "
            for ((j = 0; j < i; j++)); do indent="$indent    "; done
            if [ "$i" -lt $((n - 1)) ]; then
                printf '%s%s/\n' "$indent" "${parts[$i]}"
            else
                printf '%s%s\n' "$indent" "${parts[$i]}"
            fi
        done

        if [ "$n" -gt 1 ]; then
            prev=("${parts[@]:0:$((n - 1))}")
        else
            prev=()
        fi
    done < "$FILE_LIST"
}

log "$GREEN" "Starting project export..."
log "$YELLOW" "Project Path: $PROJECT_PATH"
log "$YELLOW" "Output File:  $OUTPUT_PATH"

RAW_LIST="$(mktemp)"
FILE_LIST="$(mktemp)"
TMP_OUTPUT=""
cleanup() { rm -f "$RAW_LIST" "$FILE_LIST" ${TMP_OUTPUT:+"$TMP_OUTPUT"}; }
trap cleanup EXIT

if in_git_repo; then
    log "$CYAN" "Listing files via git..."
    git ls-files -z --cached --others --exclude-standard > "$RAW_LIST"
else
    log "$YELLOW" "Not a git repo; falling back to find..."
    find . -type f -print0 > "$RAW_LIST"
fi

while IFS= read -r -d '' file; do
    rel="${file#./}"
    [ "$rel" = "$OUTPUT_REL" ] && continue
    is_excluded_path "$rel" && continue
    is_included_file "$rel" || continue
    [ -f "$rel" ] || continue
    is_text "$rel" || continue
    printf '%s\0' "$rel"
done < "$RAW_LIST" | LC_ALL=C sort -z -u > "$FILE_LIST"

FILE_COUNT=0
while IFS= read -r -d '' _; do FILE_COUNT=$((FILE_COUNT + 1)); done < "$FILE_LIST"
log "$GREEN" "Found $FILE_COUNT files to export"

GIT_COMMIT="n/a"; GIT_BRANCH="n/a"; GIT_DIRTY="n/a"
if in_git_repo; then
    commit="$(git rev-parse --verify --quiet HEAD 2>/dev/null || true)"
    [ -n "$commit" ] && GIT_COMMIT="$commit"
    branch="$(git branch --show-current 2>/dev/null || true)"
    [ -n "$branch" ] && GIT_BRANCH="$branch"

    status_args=(status --porcelain -- . ":(exclude)$OUTPUT_REL")
    if [ -n "$(git "${status_args[@]}" 2>/dev/null || true)" ]; then
        GIT_DIRTY="yes (uncommitted changes are included below)"
    else
        GIT_DIRTY="no"
    fi
fi
FLUTTER_VERSION="$( (flutter --version 2>/dev/null || true) | awk 'NR==1')"
[ -n "$FLUTTER_VERSION" ] || FLUTTER_VERSION="not installed"

TMP_OUTPUT="$(mktemp "$OUTPUT_DIR/.export.XXXXXX")"

{
    echo "==============================================================================="
    echo "PROJECT EXPORT"
    echo "Generated (UTC): $(date -u '+%Y-%m-%d %H:%M:%S')"
    echo "Project Path:    $PROJECT_PATH"
    echo "Git Commit:      $GIT_COMMIT"
    echo "Git Branch:      $GIT_BRANCH"
    echo "Git Dirty:       $GIT_DIRTY"
    echo "Flutter:         $FLUTTER_VERSION"
    echo "Files Exported:  $FILE_COUNT"
    echo "==============================================================================="
    echo
    echo "DIRECTORY STRUCTURE (exported files only):"
    echo "=========================================="
    echo
    render_tree
    printf '\n\n'
    echo "FILE CONTENTS:"
    echo "=============="
    echo
} > "$TMP_OUTPUT"

TOTAL_BYTES=0
CURRENT=0
while IFS= read -r -d '' rel; do
    CURRENT=$((CURRENT + 1))
    full="$PROJECT_PATH/$rel"

    size="$(wc -c < "$full" | tr -d ' ')"
    lines="$(line_count_of "$full")"
    size_kb="$(awk "BEGIN {printf \"%.2f\", $size / 1024}")"
    hash="$(sha256_of "$full")"
    modified="$(mod_time_utc_of "$full")"
    TOTAL_BYTES=$((TOTAL_BYTES + size))

    log "$CYAN" "Processing ($CURRENT/$FILE_COUNT): $rel"

    {
        echo "================================================================================"
        echo "FILE:     $rel"
        echo "SIZE:     ${size_kb} KB (${size} bytes)"
        echo "LINES:    $lines"
        echo "SHA256:   $hash"
        echo "MODIFIED: $modified (UTC)"
        echo "================================================================================"
        echo
    } >> "$TMP_OUTPUT"

    if [ -s "$full" ]; then
        cat "$full" >> "$TMP_OUTPUT" 2>/dev/null || echo "[ERROR READING FILE]" >> "$TMP_OUTPUT"
    else
        echo "[EMPTY FILE]" >> "$TMP_OUTPUT"
    fi

    printf '\n\n' >> "$TMP_OUTPUT"
done < "$FILE_LIST"

TOTAL_MB="$(awk "BEGIN {printf \"%.2f\", $TOTAL_BYTES / 1048576}")"

{
    echo "==============================================================================="
    echo "EXPORT COMPLETED (UTC): $(date -u '+%Y-%m-%d %H:%M:%S')"
    echo "Total Files Exported:   $FILE_COUNT"
    echo "Total Source Size:      ${TOTAL_MB} MB (${TOTAL_BYTES} bytes)"
    echo "Output File:            $OUTPUT_PATH"
    echo "==============================================================================="
} >> "$TMP_OUTPUT"

DUMP_HASH="$(sha256_of "$TMP_OUTPUT")"
echo "DUMP SHA256 (of all lines above this one): $DUMP_HASH" >> "$TMP_OUTPUT"

chmod 0644 "$TMP_OUTPUT"
mv -f "$TMP_OUTPUT" "$OUTPUT_PATH"
TMP_OUTPUT=""

log "$GREEN" ""
log "$GREEN" "Export completed successfully!"
log "$YELLOW" "Output file: $OUTPUT_PATH"
log "$CYAN" "Total source size: ${TOTAL_MB} MB across ${FILE_COUNT} files"
lib/domain/services/best_move_finder.dart (new)
dart
import 'dart:math';

import 'package:match3/domain/models/level_goal.dart';
import 'package:match3/domain/models/tile_model.dart';

class _Cell {
  _Cell(this.id, this.emoji, this.type, this.frozen, this.crateHp);

  final String id;
  String? emoji;
  TileType type;
  bool frozen;
  int crateHp;

  bool get canSwap => !frozen && type != TileType.crate;

  _Cell clone() => _Cell(id, emoji, type, frozen, crateHp);
}

class _Scan {
  _Scan(this.matched, this.specials);

  final List<int> matched;
  final Map<int, TileType> specials;
}

class _Outcome {
  int points = 0;
  int targetFruit = 0;
  int specials = 0;
  int specialValue = 0;
  int combos = 0;
  int jelly = 0;
  int obstacles = 0;
}

class BestMoveFinder {
  BestMoveFinder({
    required this.rows,
    required this.cols,
    required this.goal,
    required this.jellyTiles,
    required this.colorBombEmoji,
  });

  final int rows;
  final int cols;
  final LevelGoal goal;
  final Set<String> jellyTiles;
  final String colorBombEmoji;

  int get _size => rows * cols;

  List<TileModel>? findBestSwap(List<TileModel> tiles) {
    final origin = List<TileModel?>.filled(_size, null);
    final base = _buildGrid(tiles, origin);
    List<TileModel>? best;
    var bestValue = double.negativeInfinity;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final a = r * cols + c;
        if (origin[a] == null || !base[a]!.canSwap) continue;
        for (final next in [(r, c + 1), (r + 1, c)]) {
          if (next.$1 >= rows || next.$2 >= cols) continue;
          final b = next.$1 * cols + next.$2;
          if (origin[b] == null || !base[b]!.canSwap) continue;

          final double value;
          if (_isSpecialCombo(base[a]!, base[b]!)) {
            value = (_evaluate(_simulateSwap(base, a, b)!) + _evaluate(_simulateSwap(base, b, a)!)) / 2;
          } else {
            final outcome = _simulateSwap(base, a, b);
            if (outcome == null) continue;
            value = _evaluate(outcome);
          }

          if (value > bestValue) {
            bestValue = value;
            best = [origin[a]!, origin[b]!];
          }
        }
      }
    }
    return best;
  }

  List<TileModel>? findBestTwist(List<TileModel> tiles) {
    final origin = List<TileModel?>.filled(_size, null);
    final base = _buildGrid(tiles, origin);
    List<TileModel>? best;
    var bestValue = double.negativeInfinity;

    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < cols - 1; c++) {
        final tl = r * cols + c;
        final tr = r * cols + c + 1;
        final br = (r + 1) * cols + c + 1;
        final bl = (r + 1) * cols + c;
        final cluster = [tl, tr, br, bl];
        if (cluster.any((i) => origin[i] == null || !base[i]!.canSwap)) continue;

        final g = _clone(base);
        g[tr] = base[tl]!.clone();
        g[br] = base[tr]!.clone();
        g[bl] = base[br]!.clone();
        g[tl] = base[bl]!.clone();

        final prio = {for (final i in cluster) base[i]!.id};
        if (_scan(g, prio).matched.isEmpty) continue;

        final outcome = _Outcome();
        _resolve(g, prio, outcome, Set<String>.of(jellyTiles), 0);
        final value = _evaluate(outcome);
        if (value > bestValue) {
          bestValue = value;
          best = [for (final i in cluster) origin[i]!];
        }
      }
    }
    return best;
  }

  List<_Cell?> _buildGrid(List<TileModel> tiles, List<TileModel?> origin) {
    final g = List<_Cell?>.filled(_size, null);
    for (final t in tiles) {
      if (t.row < 0 || t.row >= rows || t.col < 0 || t.col >= cols) continue;
      final i = t.row * cols + t.col;
      g[i] = _Cell(t.id, t.emoji, t.type, t.isFrozen, t.crateHealth);
      origin[i] = t;
    }
    for (var i = 0; i < _size; i++) {
      g[i] ??= _unknown();
    }
    return g;
  }

  _Cell _unknown() => _Cell('', null, TileType.normal, false, 0);

  List<_Cell?> _clone(List<_Cell?> g) => List<_Cell?>.generate(_size, (i) => g[i]!.clone());

  String _key(int i) => '${i ~/ cols}_${i % cols}';

  bool _isSpecialCombo(_Cell a, _Cell b) {
    if (a.type == TileType.colorBomb || b.type == TileType.colorBomb) return true;
    return a.type != TileType.normal && b.type != TileType.normal;
  }

  _Outcome? _simulateSwap(List<_Cell?> base, int a, int b) {
    final g = _clone(base);
    final first = g[a]!;
    final second = g[b]!;
    g[a] = second;
    g[b] = first;

    final outcome = _Outcome();
    final jelly = Set<String>.of(jellyTiles);

    if (_isSpecialCombo(first, second)) {
      _applySpecialCombo(g, b, a, outcome, jelly);
      _resolve(g, const {}, outcome, jelly, 1);
      return outcome;
    }

    final prio = {first.id, second.id};
    if (_scan(g, prio).matched.isEmpty) return null;
    _resolve(g, prio, outcome, jelly, 0);
    return outcome;
  }

  void _applySpecialCombo(List<_Cell?> g, int p1, int p2, _Outcome outcome, Set<String> jelly) {
    final t1 = g[p1]!;
    final t2 = g[p2]!;
    final b1 = t1.type == TileType.colorBomb;
    final b2 = t2.type == TileType.colorBomb;
    final s1 = t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical;
    final s2 = t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical;
    final w1 = t1.type == TileType.wrapped;
    final w2 = t2.type == TileType.wrapped;
    final tr = p1 ~/ cols;
    final tc = p1 % cols;
    final all = List<int>.generate(_size, (i) => i);
    final destroy = <int>{p1, p2};

    List<int> sameColor(_Cell other) =>
        other.emoji == null ? const [] : all.where((i) => g[i]!.emoji == other.emoji).toList();

    if (b1 && b2) {
      destroy.addAll(all);
    } else if ((b1 && s2) || (b2 && s1)) {
      final matching = sameColor(b1 ? t2 : t1);
      destroy.addAll(matching);
      for (final m in matching) {
        destroy.addAll(all.where((i) => i ~/ cols == m ~/ cols || i % cols == m % cols));
      }
    } else if ((b1 && w2) || (b2 && w1)) {
      final matching = sameColor(b1 ? t2 : t1);
      destroy.addAll(matching);
      for (final m in matching) {
        destroy.addAll(all.where((i) => (i ~/ cols - m ~/ cols).abs() <= 1 && (i % cols - m % cols).abs() <= 1));
      }
    } else if (b1 || b2) {
      destroy.addAll(sameColor(b1 ? t2 : t1));
    } else if (s1 && s2) {
      destroy.addAll(all.where((i) => i ~/ cols == tr || i % cols == tc));
    } else if ((s1 && w2) || (s2 && w1)) {
      destroy.addAll(all.where((i) => (i ~/ cols - tr).abs() <= 1 || (i % cols - tc).abs() <= 1));
    } else if (w1 && w2) {
      destroy.addAll(all.where((i) => (i ~/ cols - tr).abs() <= 2 && (i % cols - tc).abs() <= 2));
    }

    outcome.points += destroy.length * 60;
    for (final i in destroy) {
      if (jelly.remove(_key(i))) outcome.jelly++;
      if (goal.targetFruitEmoji != null && g[i]!.emoji == goal.targetFruitEmoji) outcome.targetFruit++;
    }
    for (final i in destroy) {
      g[i] = null;
    }
    _cascade(g);
  }

  void _resolve(List<_Cell?> g, Set<String> prio, _Outcome outcome, Set<String> jelly, int combo) {
    var first = true;
    for (var guard = 0; guard < 200; guard++) {
      final scan = _scan(g, first ? prio : const {});
      first = false;
      if (scan.matched.isEmpty) return;

      final exploded = _explode(g, scan.matched);
      final finalExploded = exploded.difference(scan.specials.keys.toSet());

      outcome.points += finalExploded.length * 50;
      for (final i in exploded) {
        if (jelly.remove(_key(i))) outcome.jelly++;
      }
      for (final i in finalExploded) {
        if (goal.targetFruitEmoji != null && g[i]!.emoji == goal.targetFruitEmoji) outcome.targetFruit++;
      }
      outcome.specials += scan.specials.length;
      for (final type in scan.specials.values) {
        outcome.specialValue += _specialWorth(type);
      }
      if (combo > 0) outcome.combos++;
      combo++;

      scan.specials.forEach((i, type) {
        g[i]!.type = type;
        if (type == TileType.colorBomb) g[i]!.emoji = colorBombEmoji;
      });

      for (var i = 0; i < _size; i++) {
        if (finalExploded.contains(i) || !_isAdjacent(i, finalExploded)) continue;
        final cell = g[i]!;
        if (cell.frozen) {
          cell.frozen = false;
          outcome.obstacles++;
        } else if (cell.type == TileType.crate) {
          cell.crateHp--;
          outcome.obstacles++;
          if (cell.crateHp <= 0) {
            cell.type = TileType.normal;
            cell.crateHp = 0;
            cell.emoji = null;
          }
        }
      }

      for (final i in finalExploded) {
        g[i] = null;
      }
      _cascade(g);
    }
  }

  bool _isAdjacent(int i, Set<int> targets) {
    final r = i ~/ cols;
    final c = i % cols;
    return (c > 0 && targets.contains(i - 1)) ||
        (c < cols - 1 && targets.contains(i + 1)) ||
        (r > 0 && targets.contains(i - cols)) ||
        (r < rows - 1 && targets.contains(i + cols));
  }

  int _specialWorth(TileType type) {
    switch (type) {
      case TileType.stripedHorizontal:
      case TileType.stripedVertical:
        return 150;
      case TileType.wrapped:
        return 200;
      case TileType.colorBomb:
        return 300;
      default:
        return 0;
    }
  }

  bool _same(_Cell a, _Cell b) => a.emoji != null && a.emoji == b.emoji;

  int _pick(List<_Cell?> g, List<int> line, Set<String> prio, int fallback) {
    for (final i in line) {
      if (prio.contains(g[i]!.id)) return i;
    }
    return line[fallback];
  }

  _Scan _scan(List<_Cell?> g, Set<String> prio) {
    final matched = <int>{};
    final specials = <int, TileType>{};
    final horizontal = <Set<int>>[];
    final vertical = <Set<int>>[];

    for (var r = 0; r < rows; r++) {
      var start = 0;
      for (var c = 1; c <= cols; c++) {
        final current = c < cols ? g[r * cols + c] : null;
        final startCell = g[r * cols + start]!;
        if (current != null && _same(current, startCell) && current.type != TileType.colorBomb) continue;
        final length = c - start;
        if (length >= 3) {
          final line = [for (var i = start; i < c; i++) r * cols + i];
          matched.addAll(line);
          horizontal.add(line.toSet());
          if (length == 4) {
            specials[_pick(g, line, prio, 1)] = TileType.stripedHorizontal;
          } else if (length >= 5) {
            specials[_pick(g, line, prio, 2)] = TileType.colorBomb;
          }
        }
        start = c;
      }
    }

    for (var c = 0; c < cols; c++) {
      var start = 0;
      for (var r = 1; r <= rows; r++) {
        final current = r < rows ? g[r * cols + c] : null;
        final startCell = g[start * cols + c]!;
        if (current != null && _same(current, startCell) && current.type != TileType.colorBomb) continue;
        final length = r - start;
        if (length >= 3) {
          final line = [for (var i = start; i < r; i++) i * cols + c];
          matched.addAll(line);
          vertical.add(line.toSet());
          if (length == 4) {
            specials[_pick(g, line, prio, 1)] = TileType.stripedVertical;
          } else if (length >= 5) {
            specials[_pick(g, line, prio, 2)] = TileType.colorBomb;
          }
        }
        start = r;
      }
    }

    for (final h in horizontal) {
      for (final v in vertical) {
        final intersection = h.intersection(v);
        if (intersection.isNotEmpty && specials[intersection.first] != TileType.colorBomb) {
          specials[intersection.first] = TileType.wrapped;
        }
      }
    }

    return _Scan(matched.toList(), specials);
  }

  Set<int> _explode(List<_Cell?> g, List<int> initial) {
    final exploded = <int>{...initial};
    final queue = List<int>.of(initial);
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final r = current ~/ cols;
      final c = current % cols;
      final type = g[current]!.type;
      Iterable<int> targets;
      if (type == TileType.stripedHorizontal) {
        targets = [for (var cc = 0; cc < cols; cc++) r * cols + cc];
      } else if (type == TileType.stripedVertical) {
        targets = [for (var rr = 0; rr < rows; rr++) rr * cols + c];
      } else if (type == TileType.wrapped) {
        targets = [
          for (var rr = max(0, r - 1); rr <= min(rows - 1, r + 1); rr++)
            for (var cc = max(0, c - 1); cc <= min(cols - 1, c + 1); cc++) rr * cols + cc
        ];
      } else {
        continue;
      }
      for (final t in targets) {
        if (exploded.add(t)) queue.add(t);
      }
    }
    return exploded;
  }

  void _cascade(List<_Cell?> g) {
    for (var c = 0; c < cols; c++) {
      var target = rows - 1;
      for (var r = rows - 1; r >= 0; r--) {
        final cell = g[r * cols + c];
        if (cell == null) continue;
        g[r * cols + c] = null;
        g[target * cols + c] = cell;
        target--;
      }
      while (target >= 0) {
        g[target * cols + c] = _unknown();
        target--;
      }
    }
  }

  double _evaluate(_Outcome o) {
    final remaining = max(0, goal.targetValue - goal.currentValue);
    final progress = switch (goal.type) {
      LevelGoalType.score => o.points,
      LevelGoalType.targetFruit => o.targetFruit,
      LevelGoalType.createSpecials => o.specials,
      LevelGoalType.comboMaster => o.combos,
      LevelGoalType.clearJelly => o.jelly,
    };
    var value = (o.points + o.specialValue + o.obstacles * 40).toDouble();
    if (goal.type != LevelGoalType.score) value += min(progress, remaining) * 1000;
    if (remaining > 0 && progress >= remaining) value += 1e9;
    return value;
  }
}
lib/ui/features/game/view_models/game_view_model.dart
Changes in this file:

New import for best_move_finder.dart.
New findBestMove(), used by the hint timer.
canSwap check added in swapTiles.
The four existing comments removed.
dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:match3/data/repositories/progress_repository.dart';
import 'package:match3/domain/models/game_state_model.dart';
import 'package:match3/domain/models/level_generator.dart';
import 'package:match3/domain/models/level_goal.dart';
import 'package:match3/domain/models/tile_model.dart';
import 'package:match3/domain/services/best_move_finder.dart';

class GameViewModel extends ChangeNotifier {
  final ProgressRepository progressRepository;
  final Random _random = Random();

  late LevelConfig _levelConfig;
  bool _isZenMode = false;
  bool _isTimeAttack = false;
  bool _isTwistMode = false;
  bool get isTwistMode => _isTwistMode;
  late LevelGoal _currentGoal;
  Timer? _hintTimer;
  Timer? _timeAttackTimer;
  Set<String> _lastSwappedTileIds = const {};

  GameStateModel _state = const GameStateModel(
    tiles: [],
    score: 0,
    highScore: 0,
    movesLeft: 25,
    targetScore: 1000,
    isGameOver: false,
    rows: 8,
    cols: 8,
    comboCount: 0,
    levelNumber: 1,
  );

  GameStateModel get state => _state;
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  GameViewModel({
    required this.progressRepository,
  });

  @override
  void dispose() {
    _hintTimer?.cancel();
    _timeAttackTimer?.cancel();
    super.dispose();
  }

  Future<void> initGame({int level = 1, bool isZenMode = false, bool isTimeAttack = false, bool isTwistMode = false}) async {
    _hintTimer?.cancel();
    _timeAttackTimer?.cancel();
    _isZenMode = isZenMode;
    _isTimeAttack = isTimeAttack;
    _isTwistMode = isTwistMode;

    final userProgress = await progressRepository.getProgress();
    _levelConfig = LevelGenerator.generate(
      level,
      isZenMode: isZenMode || isTimeAttack || isTwistMode,
      rows: 8,
      cols: 8,
      activeFruits: userProgress.activeEmojiSet,
      disableTimedChallenges: userProgress.disableTimedChallenges,
    );
    _currentGoal = isTimeAttack
        ? const LevelGoal(
            type: LevelGoalType.score,
            title: 'TIME ATTACK',
            description: 'Score as much as you can before time runs out!',
            targetValue: 999999,
          )
        : (isTwistMode
            ? const LevelGoal(
                type: LevelGoalType.score,
                title: 'TWIST MODE',
                description: 'Rotate clockwise to match and relax',
                targetValue: 999999,
              )
            : _levelConfig.goal);
    final effectiveHighScore = userProgress.levelStars[level.toString()] != null
        ? userProgress.levelStars[level.toString()]! * 1000
        : 0;

    final initialTiles = _generateInitialBoard(8, 8, _levelConfig.fruitVarietyCount, _levelConfig.frozenTiles, _levelConfig.crateTiles);

    _state = GameStateModel(
      tiles: initialTiles,
      score: 0,
      highScore: effectiveHighScore,
      movesLeft: (isTimeAttack || isTwistMode || isZenMode || _levelConfig.isTimed) ? 999 : _levelConfig.moves,
      targetScore: _levelConfig.targetScore,
      goal: _currentGoal,
      isGameOver: false,
      rows: 8,
      cols: 8,
      comboCount: 0,
      levelNumber: level,
      star1Score: _levelConfig.star1Score,
      star2Score: _levelConfig.star2Score,
      star3Score: _levelConfig.star3Score,
      starsEarned: 0,
      jellyTiles: _levelConfig.jellyTiles,
      hintTileIds: const {},
      isShuffling: false,
      isTimeAttack: isTimeAttack,
      isTwistMode: isTwistMode,
      timeLeft: isTimeAttack ? 60 : (_levelConfig.timeLimit ?? 0),
      levelConfig: _levelConfig,
    );
    _isProcessing = false;
    notifyListeners();
    _resetHintTimer();

    if (isTimeAttack || _levelConfig.isTimed) {
      _startTimeAttackTimer();
    }
  }

  void _startTimeAttackTimer() {
    _timeAttackTimer?.cancel();
    _timeAttackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.isGameOver) {
        timer.cancel();
        return;
      }
      final newTime = _state.timeLeft - 1;
      if (newTime <= 0) {
        timer.cancel();
        final isWin = !_isTimeAttack && _currentGoal.isCompleted;
        final stars = isWin ? calculateStars(_state.score) : (_isTimeAttack ? calculateStars(_state.score) : 0);
        _state = _state.copyWith(
          timeLeft: 0,
          isGameOver: true,
          starsEarned: stars,
        );
        if (isWin) {
          progressRepository.completeLevel(
            _state.levelNumber,
            stars,
          );
        }
        notifyListeners();
      } else {
        _state = _state.copyWith(timeLeft: newTime);
        notifyListeners();
      }
    });
  }

  int calculateStars(int score) {
    if (score >= _levelConfig.star3Score) return 3;
    if (score >= _levelConfig.star2Score) return 2;
    if (score >= _levelConfig.star1Score) return 1;
    return 1;
  }

  List<String> _getAvailableFruits(int count) {
    final activeSet = progressRepository.cachedProgress.activeEmojiSet;
    final clampedCount = count.clamp(4, activeSet.length);
    return activeSet.sublist(0, clampedCount);
  }

  List<TileModel> _generateInitialBoard(int rows, int cols, int fruitCount, [Set<String> frozen = const {}, Set<String> crates = const {}]) {
    final availableFruits = _getAvailableFruits(fruitCount);
    final tiles = <TileModel>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final key = '${r}_$c';
        if (crates.contains(key)) {
          tiles.add(TileModel(
            id: '${DateTime.now().microsecondsSinceEpoch}_${r}_${c}_${_random.nextInt(1000)}',
            row: r,
            col: c,
            emoji: progressRepository.cachedProgress.crateEmoji,
            type: TileType.crate,
            crateHealth: 2,
          ));
          continue;
        }

        final allowedFruits = List<String>.from(availableFruits);
        if (c >= 2) {
          final left1 = tiles.firstWhere((t) => t.row == r && t.col == c - 1);
          final left2 = tiles.firstWhere((t) => t.row == r && t.col == c - 2);
          if (left1.emoji == left2.emoji) {
            allowedFruits.remove(left1.emoji);
          }
        }
        if (r >= 2) {
          final up1 = tiles.firstWhere((t) => t.row == r - 1 && t.col == c);
          final up2 = tiles.firstWhere((t) => t.row == r - 2 && t.col == c);
          if (up1.emoji == up2.emoji) {
            allowedFruits.remove(up1.emoji);
          }
        }
        final emoji = allowedFruits[_random.nextInt(allowedFruits.length)];
        tiles.add(TileModel(
          id: '${DateTime.now().microsecondsSinceEpoch}_${r}_${c}_${_random.nextInt(1000)}',
          row: r,
          col: c,
          emoji: emoji,
          isFrozen: frozen.contains(key),
        ));
      }
    }
    return tiles;
  }

  void _updateGoalProgress({
    int scoreAdded = 0,
    List<TileModel> clearedTiles = const [],
    int specialsCreatedCount = 0,
    bool isCombo = false,
    int clearedJellyCount = 0,
  }) {
    int currentVal = _currentGoal.currentValue;

    switch (_currentGoal.type) {
      case LevelGoalType.score:
        currentVal = _state.score + scoreAdded;
        break;
      case LevelGoalType.targetFruit:
        final matching = clearedTiles.where((t) => t.emoji == _currentGoal.targetFruitEmoji).length;
        currentVal += matching;
        break;
      case LevelGoalType.createSpecials:
        currentVal += specialsCreatedCount;
        break;
      case LevelGoalType.comboMaster:
        if (isCombo) {
          currentVal += 1;
        }
        break;
      case LevelGoalType.clearJelly:
        currentVal += clearedJellyCount;
        break;
    }

    _currentGoal = _currentGoal.copyWith(currentValue: currentVal);
  }

  void _resetHintTimer() {
    _hintTimer?.cancel();
    if (_state.isGameOver || _isProcessing) return;

    _hintTimer = Timer(const Duration(seconds: 5), () async {
      if (_isProcessing || _state.isGameOver) return;
      final progress = await progressRepository.getProgress();
      if (!progress.hintsEnabled) return;

      final move = findBestMove();
      if (move != null) {
        _state = _state.copyWith(hintTileIds: move.map((t) => t.id).toSet());
        notifyListeners();
      }
    });
  }

  List<TileModel>? findBestMove() {
    final finder = BestMoveFinder(
      rows: _state.rows,
      cols: _state.cols,
      goal: _state.goal,
      jellyTiles: _state.jellyTiles,
      colorBombEmoji: progressRepository.cachedProgress.colorBombEmoji,
    );
    if (_isTwistMode) {
      return finder.findBestTwist(_state.tiles) ?? findPossibleTwistMove(_state.tiles, _state.rows, _state.cols);
    }
    return finder.findBestSwap(_state.tiles) ?? findPossibleMove(_state.tiles, _state.rows, _state.cols);
  }

  void clearHints() {
    if (_state.hintTileIds.isNotEmpty) {
      _state = _state.copyWith(hintTileIds: const {});
      notifyListeners();
    }
    _resetHintTimer();
  }

  List<TileModel>? findPossibleTwistMove(List<TileModel> tiles, int rows, int cols) {
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols - 1; c++) {
        final tTL = _tileAt(tiles, r, c);
        final tTR = _tileAt(tiles, r, c + 1);
        final tBR = _tileAt(tiles, r + 1, c + 1);
        final tBL = _tileAt(tiles, r + 1, c);

        if (tTL == null || tTR == null || tBR == null || tBL == null) continue;
        if (!tTL.canSwap || !tTR.canSwap || !tBR.canSwap || !tBL.canSwap) continue;

        var sim = tiles.map((t) {
          if (t.id == tTL.id) return t.copyWith(row: r, col: c + 1);
          if (t.id == tTR.id) return t.copyWith(row: r + 1, col: c + 1);
          if (t.id == tBR.id) return t.copyWith(row: r + 1, col: c);
          if (t.id == tBL.id) return t.copyWith(row: r, col: c);
          return t;
        }).toList();
        if (_findMatches(sim).isNotEmpty) return [tTL, tTR, tBR, tBL];

        sim = tiles.map((t) {
          if (t.id == tTL.id) return t.copyWith(row: r + 1, col: c + 1);
          if (t.id == tTR.id) return t.copyWith(row: r + 1, col: c);
          if (t.id == tBR.id) return t.copyWith(row: r, col: c);
          if (t.id == tBL.id) return t.copyWith(row: r, col: c + 1);
          return t;
        }).toList();
        if (_findMatches(sim).isNotEmpty) return [tTL, tTR, tBR, tBL];

        sim = tiles.map((t) {
          if (t.id == tTL.id) return t.copyWith(row: r + 1, col: c);
          if (t.id == tTR.id) return t.copyWith(row: r, col: c);
          if (t.id == tBR.id) return t.copyWith(row: r, col: c + 1);
          if (t.id == tBL.id) return t.copyWith(row: r + 1, col: c + 1);
          return t;
        }).toList();
        if (_findMatches(sim).isNotEmpty) return [tTL, tTR, tBR, tBL];
      }
    }
    return null;
  }

  TileModel? _tileAt(List<TileModel> tiles, int r, int c) {
    for (final t in tiles) {
      if (t.row == r && t.col == c) return t;
    }
    return null;
  }

  Future<bool> rotateClusterClockwise(int r, int c) async {
    if (_isProcessing || _state.isGameOver) return false;
    if (r < 0 || r >= _state.rows - 1 || c < 0 || c >= _state.cols - 1) return false;

    _hintTimer?.cancel();
    _isProcessing = true;
    _state = _state.copyWith(hintTileIds: const {});

    try {
      final tTL = _state.getTile(r, c);
      final tTR = _state.getTile(r, c + 1);
      final tBR = _state.getTile(r + 1, c + 1);
      final tBL = _state.getTile(r + 1, c);

      if (tTL == null || tTR == null || tBR == null || tBL == null) return false;
      if (!tTL.canSwap || !tTR.canSwap || !tBR.canSwap || !tBL.canSwap) return false;

      final rotatedTiles = _state.tiles.map((tile) {
        if (tile.id == tTL.id) {
          return tile.copyWith(row: r, col: c + 1);
        } else if (tile.id == tTR.id) {
          return tile.copyWith(row: r + 1, col: c + 1);
        } else if (tile.id == tBR.id) {
          return tile.copyWith(row: r + 1, col: c);
        } else if (tile.id == tBL.id) {
          return tile.copyWith(row: r, col: c);
        }
        return tile;
      }).toList();

      _state = _state.copyWith(tiles: rotatedTiles, comboCount: 0);
      _lastSwappedTileIds = {tTL.id, tTR.id, tBR.id, tBL.id};
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 260));

      final matches = _findMatches(rotatedTiles);
      if (matches.isNotEmpty) {
        await _processMatchesAndCascade();
      } else {
        if (progressRepository.cachedProgress.twistLimiterEnabled) {
          await Future.delayed(const Duration(milliseconds: 200));
          final revertedTiles = _state.tiles.map((tile) {
            if (tile.id == tTL.id) return tile.copyWith(row: r, col: c);
            if (tile.id == tTR.id) return tile.copyWith(row: r, col: c + 1);
            if (tile.id == tBR.id) return tile.copyWith(row: r + 1, col: c + 1);
            if (tile.id == tBL.id) return tile.copyWith(row: r + 1, col: c);
            return tile;
          }).toList();
          _state = _state.copyWith(tiles: revertedTiles);
          notifyListeners();
          return false;
        }
        await _checkAndPerformShuffleIfNeeded();
      }
      return true;
    } finally {
      _lastSwappedTileIds = const {};
      _isProcessing = false;
      _resetHintTimer();
    }
  }

  List<TileModel>? findPossibleMove(List<TileModel> tiles, int rows, int cols) {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final t1 = tiles.firstWhere((t) => t.row == r && t.col == c);
        if (!t1.canSwap) continue;

        if (c + 1 < cols) {
          final t2 = tiles.firstWhere((t) => t.row == r && t.col == c + 1);
          if (t2.canSwap && _isValidMove(t1, t2, tiles, rows, cols)) {
            return [t1, t2];
          }
        }

        if (r + 1 < rows) {
          final t2 = tiles.firstWhere((t) => t.row == r + 1 && t.col == c);
          if (t2.canSwap && _isValidMove(t1, t2, tiles, rows, cols)) {
            return [t1, t2];
          }
        }
      }
    }
    return null;
  }

  bool _isValidMove(TileModel t1, TileModel t2, List<TileModel> tiles, int rows, int cols) {
    if (!t1.canSwap || !t2.canSwap) return false;
    if (t1.type == TileType.colorBomb || t2.type == TileType.colorBomb) return true;
    if (t1.type != TileType.normal && t2.type != TileType.normal) return true;

    final simulated = tiles.map((t) {
      if (t.id == t1.id) return t.copyWith(row: t2.row, col: t2.col);
      if (t.id == t2.id) return t.copyWith(row: t1.row, col: t1.col);
      return t;
    }).toList();

    final matches = _findMatches(simulated);
    return matches.isNotEmpty;
  }

  bool _isSpecialCombination(TileModel t1, TileModel t2) {
    if (t1.type == TileType.colorBomb || t2.type == TileType.colorBomb) return true;
    if (t1.type != TileType.normal && t2.type != TileType.normal) return true;
    return false;
  }

  Future<bool> swapTiles(int r1, int c1, int r2, int c2) async {
    if (_isTwistMode || _isProcessing || _state.isGameOver) return false;
    if (r1 == r2 && c1 == c2) return false;
    _hintTimer?.cancel();
    _isProcessing = true;
    _state = _state.copyWith(hintTileIds: const {});

    try {
      final tile1 = _state.getTile(r1, c1);
      final tile2 = _state.getTile(r2, c2);
      if (tile1 == null || tile2 == null) {
        return false;
      }
      if (!tile1.canSwap || !tile2.canSwap) {
        return false;
      }

      final swappedTiles = _state.tiles.map((tile) {
        if (tile.id == tile1.id) {
          return tile.copyWith(row: r2, col: c2);
        } else if (tile.id == tile2.id) {
          return tile.copyWith(row: r1, col: c1);
        }
        return tile;
      }).toList();

      _state = _state.copyWith(tiles: swappedTiles);
      notifyListeners();

      if (_isSpecialCombination(tile1, tile2)) {
        final newMoves = (_isZenMode || _isTimeAttack || _levelConfig.isTimed) ? _state.movesLeft : _state.movesLeft - 1;
        _state = _state.copyWith(movesLeft: newMoves);
        await _handleSpecialCombination(tile1.copyWith(row: r2, col: c2), tile2.copyWith(row: r1, col: c1));
        return true;
      }

      final matches = _findMatches(swappedTiles);
      if (matches.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 200));
        _state = _state.copyWith(tiles: _state.tiles.map((tile) {
          if (tile.id == tile1.id) {
            return tile.copyWith(row: r1, col: c1);
          } else if (tile.id == tile2.id) {
            return tile.copyWith(row: r2, col: c2);
          }
          return tile;
        }).toList());
        notifyListeners();
        return false;
      }

      final newMoves = (_isZenMode || _isTimeAttack || _levelConfig.isTimed) ? _state.movesLeft : _state.movesLeft - 1;
      _state = _state.copyWith(movesLeft: newMoves, comboCount: 0);
      _lastSwappedTileIds = {tile1.id, tile2.id};
      notifyListeners();

      await _processMatchesAndCascade();
      return true;
    } finally {
      _lastSwappedTileIds = const {};
      _isProcessing = false;
      _resetHintTimer();
    }
  }

  Future<void> _handleSpecialCombination(TileModel t1, TileModel t2) async {
    final isT1Bomb = t1.type == TileType.colorBomb;
    final isT2Bomb = t2.type == TileType.colorBomb;
    final isT1Striped = t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical;
    final isT2Striped = t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical;
    final isT1Wrapped = t1.type == TileType.wrapped;
    final isT2Wrapped = t2.type == TileType.wrapped;

    final targetRow = t1.row;
    final targetCol = t1.col;
    final toDestroy = <TileModel>{t1, t2};

    if (isT1Bomb && isT2Bomb) {
      toDestroy.addAll(_state.tiles);
    } else if ((isT1Bomb && isT2Striped) || (isT2Bomb && isT1Striped)) {
      final other = isT1Bomb ? t2 : t1;
      final matchingColor = _state.tiles.where((t) => t.emoji == other.emoji).toList();
      toDestroy.addAll(matchingColor);
      for (final tile in matchingColor) {
        toDestroy.addAll(_state.tiles.where((t) => t.row == tile.row || t.col == tile.col));
      }
    } else if ((isT1Bomb && isT2Wrapped) || (isT2Bomb && isT1Wrapped)) {
      final other = isT1Bomb ? t2 : t1;
      final matchingColor = _state.tiles.where((t) => t.emoji == other.emoji).toList();
      toDestroy.addAll(matchingColor);
      for (final tile in matchingColor) {
        toDestroy.addAll(_state.tiles.where((t) => (t.row - tile.row).abs() <= 1 && (t.col - tile.col).abs() <= 1));
      }
    } else if (isT1Bomb || isT2Bomb) {
      final other = isT1Bomb ? t2 : t1;
      toDestroy.addAll(_state.tiles.where((t) => t.emoji == other.emoji));
    } else if (isT1Striped && isT2Striped) {
      toDestroy.addAll(_state.tiles.where((t) => t.row == targetRow || t.col == targetCol));
    } else if ((isT1Striped && isT2Wrapped) || (isT2Striped && isT1Wrapped)) {
      toDestroy.addAll(_state.tiles.where((t) => (t.row - targetRow).abs() <= 1 || (t.col - targetCol).abs() <= 1));
    } else if (isT1Wrapped && isT2Wrapped) {
      toDestroy.addAll(_state.tiles.where((t) => (t.row - targetRow).abs() <= 2 && (t.col - targetCol).abs() <= 2));
    }

    final toDestroyList = toDestroy.toList();
    final remainingJelly = Set<String>.from(_state.jellyTiles);
    int clearedJelly = 0;
    for (final t in toDestroyList) {
      final key = '${t.row}_${t.col}';
      if (remainingJelly.remove(key)) {
        clearedJelly++;
      }
    }

    final scoreAdded = toDestroyList.length * 60;
    final newScore = _state.score + scoreAdded;
    _updateGoalProgress(
      scoreAdded: scoreAdded,
      clearedTiles: toDestroyList,
      specialsCreatedCount: 0,
      isCombo: _state.comboCount > 0,
      clearedJellyCount: clearedJelly,
    );

    final stars = calculateStars(newScore);
    final remaining = _state.tiles.where((t) => !toDestroy.any((d) => d.id == t.id)).toList();

    _state = _state.copyWith(
      tiles: remaining,
      score: newScore,
      goal: _currentGoal,
      highScore: max(newScore, _state.highScore),
      comboCount: _state.comboCount + 1,
      starsEarned: stars,
      jellyTiles: remainingJelly,
    );
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));

    final cascaded = _cascadeBoard(_state.tiles);
    _state = _state.copyWith(tiles: cascaded);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 350));

    await _processMatchesAndCascade();
  }

  Future<void> _processMatchesAndCascade() async {
    bool isFirstScan = true;
    while (true) {
      final scanResult = _scanAndGenerateSpecials(_state.tiles, isFirstScan ? _lastSwappedTileIds : const {});
      isFirstScan = false;
      final rawMatches = scanResult.matched;
      if (rawMatches.isEmpty) break;

      final exploded = _resolveExplosions(rawMatches, _state.tiles);
      final explodedIds = exploded.map((e) => e.id).toSet();

      final updatedTiles = _state.tiles.map((tile) {
        if (scanResult.specials.containsKey(tile.id)) {
          final type = scanResult.specials[tile.id]!;
          return tile.copyWith(
            type: type,
            emoji: type == TileType.colorBomb ? progressRepository.cachedProgress.colorBombEmoji : tile.emoji,
          );
        }
        return tile;
      }).toList();

      final keptSpecialIds = scanResult.specials.keys.toSet();
      final finalExplodedIds = explodedIds.difference(keptSpecialIds);

      final scoreIncrease = finalExplodedIds.length * 50;
      final newScore = _state.score + scoreIncrease;

      final destroyedTiles = _state.tiles.where((t) => finalExplodedIds.contains(t.id)).toList();
      final remainingJelly = Set<String>.from(_state.jellyTiles);
      int clearedJelly = 0;
      for (final t in exploded) {
        final key = '${t.row}_${t.col}';
        if (remainingJelly.remove(key)) {
          clearedJelly++;
        }
      }

      final postDamageTiles = updatedTiles.map((tile) {
        if (finalExplodedIds.contains(tile.id)) return tile;
        final isAdjacent = destroyedTiles.any((d) =>
            (d.row == tile.row && (d.col - tile.col).abs() == 1) ||
            (d.col == tile.col && (d.row - tile.row).abs() == 1));

        if (isAdjacent) {
          if (tile.isFrozen) {
            return tile.copyWith(isFrozen: false);
          } else if (tile.type == TileType.crate) {
            final nextHp = tile.crateHealth - 1;
            if (nextHp <= 0) {
              return tile.copyWith(
                type: TileType.normal,
                crateHealth: 0,
                emoji: _getAvailableFruits(4)[_random.nextInt(4)],
              );
            } else {
              return tile.copyWith(crateHealth: nextHp);
            }
          }
        }
        return tile;
      }).toList();

      _updateGoalProgress(
        scoreAdded: scoreIncrease,
        clearedTiles: destroyedTiles,
        specialsCreatedCount: scanResult.specials.length,
        isCombo: _state.comboCount > 0,
        clearedJellyCount: clearedJelly,
      );

      final stars = calculateStars(newScore);
      final remaining = postDamageTiles.where((t) => !finalExplodedIds.contains(t.id)).toList();

      _state = _state.copyWith(
        tiles: remaining,
        score: newScore,
        goal: _currentGoal,
        highScore: max(newScore, _state.highScore),
        comboCount: _state.comboCount + 1,
        starsEarned: stars,
        jellyTiles: remainingJelly,
      );
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));

      final cascadedTiles = _cascadeBoard(_state.tiles);
      _state = _state.copyWith(tiles: cascadedTiles);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 350));
    }

    final isGoalCompleted = _currentGoal.isCompleted;
    if (!_isZenMode && !_isTwistMode && !_levelConfig.isTimed && isGoalCompleted && _state.movesLeft > 0) {
      await _triggerSugarCrush();
    } else if (!_isZenMode && !_isTwistMode && ((_levelConfig.isTimed ? _state.timeLeft <= 0 : _state.movesLeft <= 0) || isGoalCompleted)) {
      _timeAttackTimer?.cancel();
      final finalStars = isGoalCompleted ? calculateStars(_state.score) : 0;
      _state = _state.copyWith(
        isGameOver: true,
        starsEarned: finalStars,
      );
      if (isGoalCompleted) {
        await progressRepository.completeLevel(
          _state.levelNumber,
          finalStars,
        );
      }
      notifyListeners();
    } else {
      await _checkAndPerformShuffleIfNeeded();
    }
  }

  Future<void> _triggerSugarCrush() async {
    _state = _state.copyWith(isSugarCrush: true);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1000));

    final createdSpecialIds = <String>[];

    while (_state.movesLeft > 0) {
      final candidates = _state.tiles.where((t) => t.type == TileType.normal && !t.isFrozen && !createdSpecialIds.contains(t.id)).toList();
      if (candidates.isEmpty) break;

      final target = candidates[_random.nextInt(candidates.length)];
      final rand = _random.nextInt(3);
      final specialType = rand == 0
          ? TileType.stripedHorizontal
          : (rand == 1 ? TileType.stripedVertical : TileType.wrapped);

      createdSpecialIds.add(target.id);

      final transformedTiles = _state.tiles.map((t) {
        if (t.id == target.id) {
          return t.copyWith(type: specialType);
        }
        return t;
      }).toList();

      final newScore = _state.score + 500;
      final newStars = calculateStars(newScore);

      _state = _state.copyWith(
        movesLeft: _state.movesLeft - 1,
        tiles: transformedTiles,
        score: newScore,
        starsEarned: newStars,
      );
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 280));
    }

    await Future.delayed(const Duration(milliseconds: 400));

    for (final specialId in createdSpecialIds) {
      final tile = _state.tiles.where((t) => t.id == specialId).firstOrNull;
      if (tile == null || tile.type == TileType.normal) continue;

      final exploded = _resolveExplosions([tile], _state.tiles);
      final explodedIds = exploded.map((e) => e.id).toSet();

      final destroyedTiles = _state.tiles.where((t) => explodedIds.contains(t.id)).toList();
      final remainingJelly = Set<String>.from(_state.jellyTiles);
      for (final t in destroyedTiles) {
        remainingJelly.remove('${t.row}_${t.col}');
      }

      final scoreGain = explodedIds.length * 80;
      final updatedScore = _state.score + scoreGain;
      final remaining = _state.tiles.where((t) => !explodedIds.contains(t.id)).toList();

      _state = _state.copyWith(
        tiles: remaining,
        score: updatedScore,
        starsEarned: calculateStars(updatedScore),
        jellyTiles: remainingJelly,
        comboCount: _state.comboCount + 1,
      );
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 320));

      final cascadedTiles = _cascadeBoard(_state.tiles);
      _state = _state.copyWith(tiles: cascadedTiles);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 380));
    }

    await _processMatchesAndCascade();

    final finalStars = calculateStars(_state.score);
    _state = _state.copyWith(
      isGameOver: true,
      isSugarCrush: false,
      starsEarned: finalStars,
    );
    await progressRepository.completeLevel(
      _state.levelNumber,
      finalStars,
    );
    notifyListeners();
  }

  Future<void> _checkAndPerformShuffleIfNeeded() async {
    if (_state.isGameOver) return;
    final move = _isTwistMode
        ? findPossibleTwistMove(_state.tiles, _state.rows, _state.cols)
        : findPossibleMove(_state.tiles, _state.rows, _state.cols);
    if (move != null) return;

    _state = _state.copyWith(isShuffling: true);
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));

    final nonSpecials = _state.tiles.where((t) => t.type == TileType.normal).toList();
    final emojis = nonSpecials.map((t) => t.emoji).toList();

    int attempts = 0;
    while (attempts < 50) {
      attempts++;
      emojis.shuffle(_random);
      int idx = 0;
      final candidateTiles = _state.tiles.map((t) {
        if (t.type == TileType.normal) {
          final res = t.copyWith(emoji: emojis[idx]);
          idx++;
          return res;
        }
        return t;
      }).toList();

      final existingMatches = _findMatches(candidateTiles);
      if (existingMatches.isEmpty) {
        final possibleMove = _isTwistMode
            ? findPossibleTwistMove(candidateTiles, _state.rows, _state.cols)
            : findPossibleMove(candidateTiles, _state.rows, _state.cols);
        if (possibleMove != null) {
          _state = _state.copyWith(tiles: candidateTiles, isShuffling: false);
          notifyListeners();
          return;
        }
      }
    }

    final freshTiles = _generateInitialBoard(_state.rows, _state.cols, _levelConfig.fruitVarietyCount);
    _state = _state.copyWith(tiles: freshTiles, isShuffling: false);
    notifyListeners();
  }

  ScanResult _scanAndGenerateSpecials(List<TileModel> tiles, [Set<String> prioritizedTileIds = const {}]) {
    final matched = <TileModel>{};
    final specials = <String, TileType>{};
    final horizMatches = <Set<String>>[];
    final vertMatches = <Set<String>>[];

    for (int r = 0; r < _state.rows; r++) {
      int matchStart = 0;
      for (int c = 1; c <= _state.cols; c++) {
        final current = c < _state.cols ? tiles.firstWhere((t) => t.row == r && t.col == c) : null;
        final startTile = tiles.firstWhere((t) => t.row == r && t.col == matchStart);

        if (current != null && current.emoji == startTile.emoji && current.type != TileType.colorBomb) {
          continue;
        } else {
          final length = c - matchStart;
          if (length >= 3) {
            final group = <String>{};
            final lineTiles = <TileModel>[];
            for (int i = matchStart; i < c; i++) {
              final t = tiles.firstWhere((item) => item.row == r && item.col == i);
              matched.add(t);
              group.add(t.id);
              lineTiles.add(t);
            }
            horizMatches.add(group);
            if (length == 4) {
              final specialTile = lineTiles.firstWhere(
                (t) => prioritizedTileIds.contains(t.id),
                orElse: () => lineTiles[1],
              );
              specials[specialTile.id] = TileType.stripedHorizontal;
            } else if (length >= 5) {
              final specialTile = lineTiles.firstWhere(
                (t) => prioritizedTileIds.contains(t.id),
                orElse: () => lineTiles[2],
              );
              specials[specialTile.id] = TileType.colorBomb;
            }
          }
          matchStart = c;
        }
      }
    }

    for (int c = 0; c < _state.cols; c++) {
      int matchStart = 0;
      for (int r = 1; r <= _state.rows; r++) {
        final current = r < _state.rows ? tiles.firstWhere((t) => t.row == r && t.col == c) : null;
        final startTile = tiles.firstWhere((t) => t.row == matchStart && t.col == c);

        if (current != null && current.emoji == startTile.emoji && current.type != TileType.colorBomb) {
          continue;
        } else {
          final length = r - matchStart;
          if (length >= 3) {
            final group = <String>{};
            final lineTiles = <TileModel>[];
            for (int i = matchStart; i < r; i++) {
              final t = tiles.firstWhere((item) => item.row == i && item.col == c);
              matched.add(t);
              group.add(t.id);
              lineTiles.add(t);
            }
            vertMatches.add(group);
            if (length == 4) {
              final specialTile = lineTiles.firstWhere(
                (t) => prioritizedTileIds.contains(t.id),
                orElse: () => lineTiles[1],
              );
              specials[specialTile.id] = TileType.stripedVertical;
            } else if (length >= 5) {
              final specialTile = lineTiles.firstWhere(
                (t) => prioritizedTileIds.contains(t.id),
                orElse: () => lineTiles[2],
              );
              specials[specialTile.id] = TileType.colorBomb;
            }
          }
          matchStart = r;
        }
      }
    }

    for (final hGroup in horizMatches) {
      for (final vGroup in vertMatches) {
        final intersection = hGroup.intersection(vGroup);
        if (intersection.isNotEmpty) {
          final intersectId = intersection.first;
          if (specials[intersectId] != TileType.colorBomb) {
            specials[intersectId] = TileType.wrapped;
          }
        }
      }
    }

    return ScanResult(matched: matched.toList(), specials: specials);
  }

  List<TileModel> _resolveExplosions(List<TileModel> initialMatches, List<TileModel> allTiles) {
    final exploded = <TileModel>{...initialMatches};
    final queue = List<TileModel>.from(initialMatches);

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (current.type == TileType.stripedHorizontal) {
        final rowTiles = allTiles.where((t) => t.row == current.row && !exploded.contains(t));
        for (final t in rowTiles) {
          exploded.add(t);
          queue.add(t);
        }
      } else if (current.type == TileType.stripedVertical) {
        final colTiles = allTiles.where((t) => t.col == current.col && !exploded.contains(t));
        for (final t in colTiles) {
          exploded.add(t);
          queue.add(t);
        }
      } else if (current.type == TileType.wrapped) {
        final blastRadius = allTiles.where((t) =>
            (t.row - current.row).abs() <= 1 &&
            (t.col - current.col).abs() <= 1 &&
            !exploded.contains(t));
        for (final t in blastRadius) {
          exploded.add(t);
          queue.add(t);
        }
      }
    }
    return exploded.toList();
  }

  List<TileModel> _cascadeBoard(List<TileModel> remainingTiles) {
    final newTiles = <TileModel>[];
    final availableFruits = _getAvailableFruits(_levelConfig.fruitVarietyCount);

    for (int c = 0; c < _state.cols; c++) {
      final colTiles = remainingTiles.where((t) => t.col == c).toList()
        ..sort((a, b) => b.row.compareTo(a.row));

      int targetRow = _state.rows - 1;
      for (final tile in colTiles) {
        newTiles.add(tile.copyWith(row: targetRow));
        targetRow--;
      }

      while (targetRow >= 0) {
        final emoji = availableFruits[_random.nextInt(availableFruits.length)];
        newTiles.add(TileModel(
          id: '${DateTime.now().microsecondsSinceEpoch}_${targetRow}_${c}_${_random.nextInt(1000)}',
          row: targetRow,
          col: c,
          emoji: emoji,
        ));
        targetRow--;
      }
    }
    return newTiles;
  }

  List<TileModel> _findMatches(List<TileModel> tiles) {
    return _scanAndGenerateSpecials(tiles).matched;
  }
}

class ScanResult {
  final List<TileModel> matched;
  final Map<String, TileType> specials;

  ScanResult({required this.matched, required this.specials});
}
README.md
markdown
# Match 3 - Free Open Source Offline Puzzle Game

Fork of [sidhant947/match3](https://github.com/sidhant947/match3). An elegant, minimal, and open-source Match-3 puzzle game built using Flutter.

[![AI-DECLARATION: copilot](https://img.shields.io/badge/䷼%20AI--DECLARATION-copilot-fee2e2?labelColor=fee2e2)](AI-DECLARATION.md)

## Fork Changes

- **Best-move hints**: the hint simulates every legal swap (or twist) through matches, specials, explosions, obstacles and cascades, and highlights the one that does the most for the current level goal. Moves that complete the goal win outright; then goal progress, then points, specials created and obstacles hit. Refill tiles are unknown, so only deterministic cascades count.
- **Frozen tiles and crates** can no longer be swapped, matching the hint and twist rules.
- **Releases**: every push to `main` publishes a full GitHub release `v<pubspec version>.<run number>` with universal and per-ABI APKs.
- `scripts/export.sh` dumps all text sources to `docs/llm/dump.txt` for LLM context.

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
Notes:

versionCode is now 100 + run number, so every release installs over the previous one. Your signing key differs from upstream’s, so your APK can’t update an install of the upstream app.
The root export.sh from your first terminal run is stale; only scripts/export.sh is current.
I left test.yml alone. It still writes the passwords to key.properties by putting the secrets straight into shell commands. If any password contains $ or quotes, copy the “Setup Keystore” step from build.yml into it.



Claude is AI and can make mistakes. Please double-check responses.






Claude finished the response

13
23
