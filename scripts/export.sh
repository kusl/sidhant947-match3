#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_PATH="${1:-$SCRIPT_DIR/..}"
OUTPUT_FILE="${2:-docs/llm/dump.txt}"

INCLUDE_EXTENSIONS="cs csproj slnx props targets json razor js mjs css html svg yml yaml sh md toml kt kts gradle properties yaml dart"
INCLUDE_NAMES=".gitignore .gitattributes .editorconfig"
EXCLUDE_NAMES="package-lock.json LICENSE"
EXCLUDE_DIRS="bin obj .vs .git node_modules .vscode .idea TestResults artifacts coverage .velixir"
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
DOTNET_VERSION="$(dotnet --version 2>/dev/null || echo 'not installed')"

TMP_OUTPUT="$(mktemp "$OUTPUT_DIR/.export.XXXXXX")"

{
    echo "==============================================================================="
    echo "PROJECT EXPORT"
    echo "Generated (UTC): $(date -u '+%Y-%m-%d %H:%M:%S')"
    echo "Project Path:    $PROJECT_PATH"
    echo "Git Commit:      $GIT_COMMIT"
    echo "Git Branch:      $GIT_BRANCH"
    echo "Git Dirty:       $GIT_DIRTY"
    echo ".NET SDK:        $DOTNET_VERSION"
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
