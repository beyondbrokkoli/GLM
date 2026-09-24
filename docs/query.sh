#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC_DIR="$SCRIPT_DIR"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

die() { echo "Error: $*" >&2; exit 1; }

# Prints documentation and usage, NO list.
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Documentation
Documentation lives in docs/, not in the source: every file under src/
has a mirrored .txt here — src/backend.rs is documented in docs/backend.txt,
as header prose plus one [function_name] section per documented function.
Sources carry no doc comments. docs/query.sh is the reader; docs/query.sh
--check every section tag must name a real fn in its source).

EOF
    echo "Usage: $0                      list documented sources"
    echo "       $0 <source-file>        header doc + documented functions"
    echo "       $0 <source-file> <fn>   one function's doc"
    echo "       $0 --check              validate all documentation against source"
    exit 0
fi

# src/foo.rs -> docs/foo.txt
doc_for() {
    printf '%s/%s.txt' "$DOC_DIR" "$(basename "${1%.rs}")"
}

list_tags() {
    grep -oE '^\[[A-Za-z0-9_]+\]$' "$1" | tr -d '[]' || true
}

# print_section <doc> [tag] — header if no tag; exit 2 if tag missing.
# Trailing blank lines are trimmed, interior blank lines kept.
print_section() {
    awk -v want="${2:-}" '
        /^\[[A-Za-z0-9_]+\]$/ {
            if (printing) exit
            if (want == "") exit
            cur = $0; sub(/^\[/, "", cur); sub(/\]$/, "", cur)
            printing = (cur == want)
            next
        }
        printing || want == "" { lines[++n] = $0 }
        END {
            if (want != "" && !printing) exit 2
            while (n > 0 && lines[n] ~ /^[ \t]*$/) n--
            for (i = 1; i <= n; i++) print lines[i]
        }
    ' "$1"
}

if [[ "${1:-}" == "--check" ]]; then
    fails=0
    checked=0

    # Every Rust source file must have a doc file here.
    while IFS= read -r src_abs; do
        rel="${src_abs#"$ROOT"/}"
        doc="$(doc_for "$rel")"
        checked=$((checked + 1))

        if [[ ! -f "$doc" ]]; then
            echo "FAIL  $rel — no doc file (${doc#"$ROOT"/})"
            fails=$((fails + 1))
            continue
        fi

        # Header must be non-empty, no duplicate tags, each tag must match
        # a real fn in the source, and no section may be empty. These
        # anchor the docs to the code so they cannot drift.
        tags="$(list_tags "$doc")"
        reasons=""
        if [[ -z "$(print_section "$doc")" ]]; then
            reasons+=" empty header;"
        fi
        if [[ -n "$(list_tags "$doc" | sort | uniq -d)" ]]; then
            reasons+=" duplicate tags;"
        fi
        while IFS= read -r tag; do
            [[ -n "$tag" ]] || continue
            if ! grep -qE "(^|[^A-Za-z0-9_])fn ${tag}\(" "$src_abs"; then
                reasons+=" [$tag] matches no fn;"
            elif [[ -z "$(print_section "$doc" "$tag")" ]]; then
                reasons+=" [$tag] is empty;"
            fi
        done <<< "$tags"

        if [[ -n "$reasons" ]]; then
            echo "FAIL  $rel —$reasons"
            fails=$((fails + 1))
        else
            echo "PASS  $rel ($(echo "$tags" | grep -c . || true) sections)"
        fi
    done < <(find "$ROOT/src" -type f -name '*.rs' | sort)

    # Every doc file must map back to an existing source file.
    while IFS= read -r doc_abs; do
        name="$(basename "$doc_abs" .txt)"
        if [[ ! -f "$ROOT/src/$name.rs" ]]; then
            echo "FAIL  ${doc_abs#"$ROOT"/} — documents nothing (src/$name.rs does not exist)"
            fails=$((fails + 1))
        fi
    done < <(find "$DOC_DIR" -maxdepth 1 -type f -name '*.txt' | sort)

    echo "-----"
    echo "$checked source files checked, $fails failed"
    if [[ "$fails" -eq 0 ]]; then
        exit 0
    fi
    exit 1
fi

# Prints NO usage, NO doc hints. ONLY lists the documented sources.
if [[ $# -eq 0 ]]; then
    (cd "$DOC_DIR" && find . -maxdepth 1 -name '*.txt' | sed 's|^\./||; s|\.txt$||' | sed 's|^|src/|; s|$|.rs|' | sort)
    exit 0
fi

src="$1"
fn="${2:-}"

[[ $# -le 2 ]] || die "expected <source-file> [function], got $# args"
[[ -f "$ROOT/$src" ]] || die "no such source file: $src (repo-root-relative, e.g. src/backend.rs)"
doc="$(doc_for "$src")"
[[ -f "$doc" ]] || die "no documentation for $src (expected ${doc#"$ROOT"/})"

if [[ -n "$fn" ]]; then
    out="$(print_section "$doc" "$fn")" || die "no [$fn] section in ${doc#"$ROOT"/} — available: $(list_tags "$doc" | tr '\n' ' ')"
    [[ -n "$out" ]] || die "[$fn] section in ${doc#"$ROOT"/} is empty"
    printf '%s\n' "$out"
else
    out="$(print_section "$doc")"
    [[ -n "$out" ]] || die "${doc#"$ROOT"/} has no header prose before its first [tag]"
    printf '%s\n' "$out"
    # The tags ARE the doc sections, and --check guarantees each tag is
    # a real fn in the source — this listing cannot drift from the code.
    # (|| true: grep exits 1 when the doc has no [tag] sections at all.)
    tags="$(list_tags "$doc" || true)"
    echo
    echo "Sections:"
    if [[ -n "$tags" ]]; then
        printf '%s\n' "$tags"
    else
        echo "(none)"
    fi
fi
