#!/usr/bin/env python3
"""plate.py — decode and diff .glm_trace.bin, the compile-run signal plate.

Layout (docs/trace-plate.md is the contract; trace_signals.txt is the SSOT):

  bytes 0..256        LOW  half: sticky booleans — "fired at least once,
                           ever", never cleared (byte N)
                      HIGH half: per-run counters — byte 128+N counts signal
                           N this run, saturating (255 = "many")
  bytes 256..33024    scope histogram — cell (signal N, scope S) at
                      256 + N*256 + S: how often N fired in scope S this
                           run, saturating (255 = "many")
  bytes 33024..33536  scope directory — scope S = (depth, parent) at
                      33024 + S*2; parent 0xFF = none; entry (0,0) = scope
                      absent this run

Signal names/owners/meanings come from trace_signals.txt — the single
source of truth. The Rust consts in src/trace.rs are generated from that
same file by build.rs, so decoder and compiler cannot drift.

SEMANTIC DECOUPLING — the one hard rule of this script: no slot ranges,
ever. Signal slots are physical addresses on the plate and nothing more;
all meaning is derived from the <NAME> field of trace_signals.txt at
runtime. Signals are grouped into FAMILIES by the prefix before the first
`_` (STMT_ASSIGN_NIL -> STMT, INFER_INT -> INFER, ELEM_FALLBACK_TBL ->
ELEM). When a future trace_signals.txt renumbers slots or adds signals,
every grouping in this decoder follows the names automatically — the only
numeric literals here are the plate geometry itself, which is fixed by
the binary contract, not by signal semantics.

Decoding rules:
  counter > 0          → fired exactly k times this run (boolean must be 1)
  boolean 1, counter 0 → boolean-only path this run (backend/runtime), or
                         sticky residue from an earlier run; for analyzer
                         slots that reads as "reachable in corpus, not
                         this case"
  scope drift          → decode two runs and diff: the first diverging
                         scope — and, inside it, the diverging family and
                         signal — localizes the behavior change. That is
                         the dual-plate mode below.

Usage:
  python3 plate.py                              single decode, default paths
  python3 plate.py plate.bin                    single decode
  python3 plate.py plate.bin signals.txt        single decode, explicit SSOT
  python3 plate.py good.bin bad.bin             DIFF — first file = good
                                                (baseline), second = bad
                                                (suspect); deltas read as
                                                "extra fires in bad.bin"
  python3 plate.py good.bin bad.bin signals.txt diff, explicit SSOT
  python3 plate.py -s signals.txt good.bin bad.bin   diff, SSOT by flag

Defaults: ./.glm_trace.bin and trace_signals.txt next to this script.
The sticky LOW half is never diffed: OR-semantics makes it cross-run
residue, not per-run state. Two runs of the same case must produce
byte-identical plates — any diff the engine reports is a behavior change
or a determinism regression (docs/trace-plate.md).
"""

import argparse
import sys
from pathlib import Path

# Plate geometry — fixed by docs/trace-plate.md, independent of the SSOT.
PLATE_LEN = 256
COUNT_BASE = 128
SCOPE_SLOTS = 256
HISTO_OFF = PLATE_LEN
DIR_OFF = HISTO_OFF + COUNT_BASE * SCOPE_SLOTS
FILE_LEN = DIR_OFF + 2 * SCOPE_SLOTS
CHRONO_HEADER_OFF = FILE_LEN  # chronology: global_seq u32 + ring_capacity u32 (LE), then the ring
PARENT_NONE = 0xFF
ABSENT = (0, 0)
SAT = 255

DEFAULT_PLATE = ".glm_trace.bin"


def load_signals(path: Path):
    """Parse trace_signals.txt: one `slot NAME owner meaning` per line."""
    signals = {}
    for lineno, raw in enumerate(path.read_text().splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        fields = line.split(None, 3)
        if len(fields) != 4:
            sys.exit(f"{path}:{lineno}: expected `<slot> <NAME> <owner> <meaning>`: {line}")
        slot_s, name, owner, meaning = fields
        if not slot_s.isdigit() or not (0 <= int(slot_s) < COUNT_BASE):
            sys.exit(f"{path}:{lineno}: slot `{slot_s}` outside 0..={COUNT_BASE - 1}")
        slot = int(slot_s)
        if slot in signals:
            sys.exit(f"{path}:{lineno}: slot {slot} double-booked ({signals[slot][0]} vs {name})")
        signals[slot] = (name, owner, meaning)
    if not signals:
        sys.exit(f"{path}: no signals declared")
    return signals


# --- semantic decoupling: families from NAME prefixes, never slot numbers ---

def signal_name(slot, signals):
    return signals[slot][0] if slot in signals else f"SLOT_{slot}"


def family_of(slot, signals):
    """Family = NAME prefix before the first `_` — never the slot number."""
    if slot not in signals:
        return "UNNAMED"
    return signals[slot][0].split("_", 1)[0]


def families(signals):
    """Ordered {family: [slots]} — the dynamic replacement for slot ranges."""
    grouped = {}
    for slot in signals:
        grouped.setdefault(family_of(slot, signals), []).append(slot)
    return {fam: sorted(slots) for fam, slots in sorted(grouped.items())}


def label(slot, signals):
    if slot in signals:
        name, owner, meaning = signals[slot]
        return f"TRACE_{name}  ({owner})" + (f" — {meaning}" if meaning else "")
    return f"SLOT_{slot}  (unnamed)"


# --- plate geometry helpers -------------------------------------------------

def load_plate(path: Path):
    """Read a plate, pad short/old files up to the classic geometry. Returns (data, full)."""
    if not path.exists():
        sys.exit(f"no plate at {path} — compile something first")
    raw = path.read_bytes()
    # The classic plate is FILE_LEN; the chronology extension appends a
    # header + ring after it, so anything >= FILE_LEN is a valid plate.
    if len(raw) < FILE_LEN:
        note = " — old plate, scope sections empty" if len(raw) < DIR_OFF else ""
        print(f"CONTRACT NOTE: {path} is {len(raw)} bytes, expected at least {FILE_LEN}{note}", file=sys.stderr)
    return raw.ljust(FILE_LEN, b"\0"), len(raw) >= FILE_LEN


def scope_entry(data, scope):
    return data[DIR_OFF + 2 * scope], data[DIR_OFF + 2 * scope + 1]


def live_scopes(data):
    """Scope ids with a directory entry this run: (0,0) means absent."""
    return [s for s in range(SCOPE_SLOTS) if scope_entry(data, s) != ABSENT]


def scope_cells(data, slot, scopes):
    """Nonzero (scope, count) histogram cells for one signal."""
    base = HISTO_OFF + slot * SCOPE_SLOTS
    return [(s, data[base + s]) for s in scopes if data[base + s] > 0]


def histo_row(data, slot):
    base = HISTO_OFF + slot * SCOPE_SLOTS
    return data[base:base + SCOPE_SLOTS]


def fmt_count(c):
    return "many(255)" if c == SAT else str(c)


def fmt_parent(p):
    return "none" if p == PARENT_NONE else f"s{p}"


def scope_head(scope, entry):
    depth, parent = entry
    return f"Scope {scope} (Depth {depth}, Parent {fmt_parent(parent)})"


def plate_violations(data, tree=True):
    """The contract checks, shared by both modes (same wording as ever)."""
    low, high = data[:COUNT_BASE], data[COUNT_BASE:PLATE_LEN]
    violations = [f"counter > 0 on an unset boolean: slot {n}"
                  for n in range(COUNT_BASE) if high[n] > 0 and low[n] != 1]
    violations += [f"low half holds non-0/1 byte: slot {n}"
                   for n in range(COUNT_BASE) if low[n] not in (0, 1)]
    violations += [f"histogram cell (slot {n}, scope {s}) > 0 but scope {s} has no directory entry"
                   for n in range(COUNT_BASE)
                   for s, c in enumerate(histo_row(data, n))
                   if c > 0 and scope_entry(data, s) == ABSENT]
    if tree:
        for s in live_scopes(data):
            parent = scope_entry(data, s)[1]
            if parent == s:
                violations.append(f"scope {s} is its own parent")
            elif parent != PARENT_NONE and scope_entry(data, parent) == ABSENT:
                violations.append(f"scope {s} names absent parent {parent}")
    return violations


def print_scope_map(data, violations):
    scopes = live_scopes(data)
    children = {s: [] for s in scopes}
    roots = []
    for s in scopes:
        depth, parent = scope_entry(data, s)
        if parent == PARENT_NONE:
            roots.append(s)
        elif parent in children:
            children[parent].append(s)
        else:
            violations.append(f"scope {s} names absent parent {parent}")

    def emit(s, indent):
        depth, parent = scope_entry(data, s)
        pad = "  " * indent
        print(f"  {pad}s{s:<3} depth {depth}" + (f"  parent s{parent}" if parent != PARENT_NONE and indent == 0 else ""))
        for child in sorted(children[s]):
            if child == s:
                violations.append(f"scope {s} is its own parent")
                return
            emit(child, indent + 1)

    print(f"\n== scope map ({len(scopes)} scopes this run) ==")
    for root in sorted(roots):
        emit(root, 0)
    return scopes


# --- single-plate mode (the original behavior) ------------------------------

def print_chronology(data, signals):
    if len(data) < CHRONO_HEADER_OFF + 8:
        print("\n== Event Chronology ==")
        print("  (absent — plate does not contain chronology extension)")
        return

    seq_total = int.from_bytes(data[CHRONO_HEADER_OFF:CHRONO_HEADER_OFF + 4], "little")
    capacity = int.from_bytes(data[CHRONO_HEADER_OFF + 4:CHRONO_HEADER_OFF + 8], "little")

    if seq_total == 0 or capacity == 0:
        print("\n== Event Chronology (none this run) ==")
        return

    dropped = max(0, seq_total - capacity)
    valid_count = min(seq_total, capacity)
    start_idx = dropped % capacity

    print(f"\n== Event Chronology ({seq_total} events total) ==")
    if dropped > 0:
        print(f"  ... [oldest {dropped} events overwritten due to {capacity}-event ring capacity] ...")

    for i in range(valid_count):
        ring_idx = (start_idx + i) % capacity
        event_off = CHRONO_HEADER_OFF + 8 + (ring_idx * 2)

        # Guard against truncated files
        if event_off + 2 > len(data):
            break

        slot, scope = data[event_off], data[event_off + 1]

        # Scope 0xFF means no context (e.g. build status signals).
        # Note: scopes beyond 254 fold into 255 (0xFF), so heavily nested
        # scopes will also read as (no scope).
        scope_str = " (no scope)" if scope == 0xFF else f" (s{scope})"
        seq_num = dropped + i + 1

        print(f"  {seq_num:04d} : {signal_name(slot, signals)}{scope_str}")


def run_single(plate_path, ssot_path, signals):
    data, _ = load_plate(plate_path)
    low, high = data[:COUNT_BASE], data[COUNT_BASE:PLATE_LEN]

    fired = [(n, high[n]) for n in range(COUNT_BASE) if high[n] > 0]
    sticky_only = [n for n in range(COUNT_BASE) if low[n] == 1 and high[n] == 0]

    print(f"plate:   {plate_path} ({len(data)} bytes)")
    print(f"signals: {len(signals)} slots in {ssot_path.name}\n")

    print(f"== fired this run ({len(fired)}) — most recent compile ==")
    if not fired:
        print("  (nothing — compiler never ran or counters were reset)")

    violations = []

    if len(data) >= FILE_LEN:
        scopes = live_scopes(data)
    else:
        scopes = []

    for n, count in sorted(fired, key=lambda x: (-x[1], x[0])):
        cells = scope_cells(data, n, scopes) if scopes else []
        line = f"  [{n:3}] x{count if count < 255 else 'many(255)':<10} {label(n, signals)}"
        if cells:
            shown = " ".join(f"s{s}×{c}" for s, c in cells[:8])
            more = f" (+{len(cells) - 8} more)" if len(cells) > 8 else ""
            line += f"\n         scopes: {shown}{more}"
        elif scopes:
            line += "  (no scope context — boolean-only or build status)"
        print(line)

    if scopes:
        print_scope_map(data, violations)
    else:
        print("\n== scope map (none — old plate or nothing recorded this run) ==")

    print_chronology(data, signals)

    print(f"\n== sticky only ({len(sticky_only)}) — ever fired, not this run ==")
    print("  analyzer slots: reachable in corpus, not this case · "
          "compiler/backend/runtime: boolean-only path this run, or residue")
    for n in sticky_only:
        print(f"  [{n:3}] 1        {label(n, signals)}")

    violations += plate_violations(data, tree=False)

    if violations:
        for v in violations:
            print(f"\nCONTRACT VIOLATION: {v}")
    else:
        print("\ncontract checks: clean (counter>0 ⇒ boolean==1, low half is 0/1, "
              "histogram cells ⇒ documented scopes)")


# --- dual-plate diff mode ----------------------------------------------------

def scope_tree_diff(good, bad):
    """Structural drift between the two scope directories: {scope: reason}."""
    drift = {}
    for s in range(SCOPE_SLOTS):
        ge, be = scope_entry(good, s), scope_entry(bad, s)
        if ge == ABSENT and be == ABSENT:
            continue
        if ge == ABSENT:
            drift[s] = f"present only in bad.bin (depth {be[0]}, parent {fmt_parent(be[1])})"
        elif be == ABSENT:
            drift[s] = f"present only in good.bin (depth {ge[0]}, parent {fmt_parent(ge[1])})"
        elif ge != be:
            drift[s] = (f"structure moved: depth {ge[0]} -> {be[0]}, "
                        f"parent {fmt_parent(ge[1])} -> {fmt_parent(be[1])}")
    return drift


def histogram_diff(good, bad):
    """Every (scope, slot) cell nonzero in either plate: {scope: {slot: (g, b)}}."""
    per_scope = {}
    for n in range(COUNT_BASE):
        row_g, row_b = histo_row(good, n), histo_row(bad, n)
        for s in range(SCOPE_SLOTS):
            if row_g[s] or row_b[s]:
                per_scope.setdefault(s, {})[n] = (row_g[s], row_b[s])
    return per_scope


def changed_cells(per_scope):
    """{scope: {slot: (g, b)}} restricted to cells that actually differ."""
    changed = {}
    for s, cells in per_scope.items():
        differing = {n: gb for n, gb in cells.items() if gb[0] != gb[1]}
        if differing:
            changed[s] = differing
    return changed


def by_family(cells, signals):
    """{family: [slots]} ordered by total |delta| desc, then family name;
    slots within a family by |delta| desc, then slot id."""
    grouped = {}
    for n in cells:
        grouped.setdefault(family_of(n, signals), []).append(n)
    fam_delta = lambda fam: sum(cells[n][1] - cells[n][0] for n in grouped[fam])
    ordered = {}
    for fam in sorted(grouped, key=lambda f: (-abs(fam_delta(f)), f)):
        ordered[fam] = sorted(grouped[fam],
                              key=lambda n: (-abs(cells[n][1] - cells[n][0]), n))
    return ordered


def family_total(cells, slots):
    return sum(cells[n][1] - cells[n][0] for n in slots)


def first_divergence_line(s, cells, good, bad, signals):
    parts = []
    for fam, slots in by_family(cells, signals).items():
        total = family_total(cells, slots)
        shown = ", ".join(f"{signal_name(n, signals)} {cells[n][1] - cells[n][0]:+d}"
                          for n in slots[:3])
        more = f", +{len(slots) - 3} more" if len(slots) > 3 else ""
        parts.append(f"[{fam}] {total:+d} ({shown}{more})")
    ge, be = scope_entry(good, s), scope_entry(bad, s)
    entry = ge if ge != ABSENT else be
    tag = " (scope presence differs)" if ge == ABSENT or be == ABSENT else ""
    return f"{scope_head(s, entry)}: " + "; ".join(parts) + tag


def run_diff(good_path, bad_path, ssot_path, signals):
    good, good_full = load_plate(good_path)
    bad, bad_full = load_plate(bad_path)

    print(f"good:    {good_path}  (baseline)")
    print(f"bad:     {bad_path}  (suspect — deltas are extra fires in bad.bin)")
    print(f"signals: {len(signals)} slots in {ssot_path.name}")
    fams = families(signals)
    print("families: " + " ".join(f"{f}[{len(ss)}]" for f, ss in fams.items())
          + f"  ({len(fams)} families — dynamic NAME prefixes, not slot ranges)")

    if good == bad:
        print("\n(plates are byte-identical — the contract's expectation for "
              "two runs of the same case)")
        checks = plate_violations(good)
        if checks:
            for v in checks:
                print(f"CONTRACT VIOLATION: {v}")
        else:
            print("contract checks: clean")
        return

    if good[:COUNT_BASE] != bad[:COUNT_BASE]:
        print("\n(note: sticky low halves differ — cross-run residue, not "
              "per-run state; excluded from this diff)")

    full = good_full and bad_full
    drift = scope_tree_diff(good, bad) if full else {}
    per_scope = histogram_diff(good, bad) if full else {}
    changed = changed_cells(per_scope)

    print("\n== Scope Tree Drift ==")
    if not full:
        short = ", ".join(str(p) for p, f in ((good_path, good_full), (bad_path, bad_full)) if not f)
        print(f"  (skipped — short/old plate without full scope sections: {short})")
    elif drift:
        for s in sorted(drift):
            print(f"  s{s}: {drift[s]}")
    else:
        print("  (none detected — scope structures match)")

    print("\n== First Divergence ==")
    if not full:
        print("  (scope counts unavailable — see counter-only deltas)")
    elif not changed and not drift:
        print("  (none — per-scope signal counts match everywhere)")
    else:
        s = min(set(changed) | set(drift))
        if s in changed:
            print("  " + first_divergence_line(s, changed[s], good, bad, signals))
        else:
            print(f"  Scope {s} — {drift[s]} (structure moved before any count delta)")
        print("  (earliest differing scope — ids are assigned in first-visit order, root = 0)")

    print("\n== Execution Divergence (bad.bin vs good.bin) ==")
    if not full:
        print("  (skipped — scope sections unavailable; see counter-only deltas)")
    elif not changed:
        print("  (none — every (signal, scope) cell matches)")
    else:
        saturated = False
        for s in sorted(changed):
            cells = changed[s]
            ge, be = scope_entry(good, s), scope_entry(bad, s)
            entry = ge if ge != ABSENT else be
            marks = []
            if ge == ABSENT:
                marks.append("new in bad.bin")
            if be == ABSENT:
                marks.append("absent in bad.bin")
            elif ge != ABSENT and ge != be:
                marks.append("structure drifted")
            suffix = (" — " + ", ".join(marks)) if marks else ""
            print(f"{scope_head(s, entry)}{suffix}:")
            for fam, slots in by_family(cells, signals).items():
                total = family_total(cells, slots)
                if total:
                    print(f"  [{fam}] family: {total:+d} fires in bad.bin")
                else:
                    print("  [{}] family: net 0 (offsetting per-signal deltas)".format(fam))
                for n in slots:
                    g, b = cells[n]
                    sat = g == SAT or b == SAT
                    saturated |= sat
                    mark = "*" if sat else ""
                    print(f"     -> {signal_name(n, signals)} ({b - g:+d}){mark}   "
                          f"({fmt_count(g)} -> {fmt_count(b)})")
        if saturated:
            print('  (* involves a saturated cell — 255 means "many", '
                  "the exact delta is unknown)")

    print("\n== Family Totals (all scopes, bad.bin vs good.bin) ==")
    totals = {}
    for cells in per_scope.values():
        for n, (g, b) in cells.items():
            t = totals.setdefault(family_of(n, signals), [0, 0])
            t[0] += g
            t[1] += b
    moved = {f: t for f, t in totals.items() if t[0] != t[1]}
    if not moved:
        print("  (no family total moved)")
    for f, (gs, bs) in sorted(moved.items(), key=lambda kv: (-(kv[1][1] - kv[1][0]), kv[0])):
        print(f"  [{f}] {bs - gs:+d}   ({gs} -> {bs})")

    print("\n== Counter-Only Deltas (no scope-tagged cells in either plate) ==")
    only = []
    for n in range(COUNT_BASE):
        if any(histo_row(good, n)) or any(histo_row(bad, n)):
            continue
        g, b = good[COUNT_BASE + n], bad[COUNT_BASE + n]
        if g != b:
            only.append((n, g, b))
    if not only:
        print("  (none — boolean-only and build-status signals match this run)")
    for n, g, b in only:
        print(f"  [{n:3}] {signal_name(n, signals)} [{family_of(n, signals)}]: "
              f"{b - g:+d} in bad.bin   ({fmt_count(g)} -> {fmt_count(b)})")

    checks = [(str(good_path), plate_violations(good)), (str(bad_path), plate_violations(bad))]
    if all(not v for _, v in checks):
        print("\ncontract checks: clean on both plates (counter>0 ⇒ boolean==1, "
              "low half is 0/1, histogram cells ⇒ documented scopes)")
    else:
        print("\ncontract checks:")
        for p, v in checks:
            for x in v:
                print(f"  CONTRACT VIOLATION ({p}): {x}")
            if not v:
                print(f"  {p}: clean")


# --- entry point --------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(
        prog="plate.py",
        description="Decode one .glm_trace.bin plate, or diff two "
                    "(good.bin bad.bin — baseline first, suspect second).")
    ap.add_argument("plates", nargs="*", metavar="PLATE",
                    help="one plate -> decode; two plates -> diff; "
                         "`plate.bin signals.txt` is the legacy single-plate form")
    ap.add_argument("-s", "--signals", metavar="FILE", type=Path,
                    help="path to trace_signals.txt (default: next to this script)")
    args = ap.parse_args()

    paths = args.plates
    if len(paths) > 3:
        ap.error("expected at most: good.bin bad.bin [signals.txt]")
    if len(paths) == 3 and args.signals is not None:
        ap.error("pass the signals file either as -s/--signals or as the third path, not both")

    # Two positional paths are a diff unless the second is the legacy
    # single-plate SSOT form (`plate.bin trace_signals.txt`).
    legacy_ssot = len(paths) == 2 and paths[1].lower().endswith(".txt") and args.signals is None
    diff = (len(paths) == 3
            or (len(paths) == 2 and (args.signals is not None or not legacy_ssot)))

    if len(paths) == 3:
        ssot_path = Path(paths[2])
    elif args.signals is not None:
        ssot_path = args.signals
    elif legacy_ssot:
        ssot_path = Path(paths[1])
    else:
        ssot_path = Path(__file__).resolve().parent / "trace_signals.txt"

    if diff:
        good_path, bad_path = Path(paths[0]), Path(paths[1])
        signals = load_signals(ssot_path)
        run_diff(good_path, bad_path, ssot_path, signals)
    else:
        plate_path = Path(paths[0]) if paths else Path(DEFAULT_PLATE)
        signals = load_signals(ssot_path)
        run_single(plate_path, ssot_path, signals)


if __name__ == "__main__":
    main()
