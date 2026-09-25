# TASK: Maintain the .glm_trace.bin plate (compile-run persistent debug data)

Any agent touching src/trace.rs, src/rt.rs, src/main.rs, or the analyzer's
signal path must uphold this contract. The plate is the persistent shadow of
the compile pipeline: its data representation is load-bearing for the planned
signal-driven state machine, so "it's just a debug file" is not a valid reason
to change it ad hoc.

## CONTEXT (verified state of the representation)

One file, ./.glm_trace.bin, slot index == byte offset for the classic
plate (so `xxd -a .glm_trace.bin` reads it straight from the shell). The
file is never truncated and lives per working directory. Sections:

- LOW half, bytes 0..128 — sticky signal booleans. Written ONLY by
  constant-1 stores: compiler via `compiler_trace_set` (src/trace.rs),
  runtime via `glm_trace_set` (src/rt.rs, MAP_SHARED over the same bytes).
  OR-semantics: once 1, stays 1. No wrap, no clear — `glm_trace_clear`
  exists but has zero callers.
- HIGH half, bytes 128..256 — per-run counter mirror. Byte 128+N counts
  trigger N in the MOST RECENT compile. Zeroed at compiler startup by
  `compiler_trace_reset_counts` (pass A, first statement of main), then
  incremented with a saturating read-modify-write — 255 means "many", it
  must never wrap.
- SCOPE HISTOGRAM, bytes 256..33024 — per-run signal × scope matrix.
  Cell (signal N, scope S) at byte 256 + N*256 + S counts how often
  signal N fired inside scope S this run, saturating independently at
  255. Zeroed at startup by `compiler_trace_scope_reset` (pass A).
- SCOPE DIRECTORY, bytes 33024..33536 — two bytes per scope id:
  (depth, parent) at 33024 + S*2; parent 0xFF = none; an all-zero entry
  means the scope was never seen this run. The root scope is (0, 0xFF).

## SIGNALS (single source of truth)

Slot names, numbers, owners, and meanings live in ONE place:
trace_signals.txt (repo root). Grammar, one signal per line:

    <slot> <NAME> <owner> <meaning>

build.rs parses it at compile time and generates the `TRACE_*` consts
that src/trace.rs includes — a duplicate slot or name fails the build.
plate.py parses the same file to decode the plate, so decoder and
compiler cannot drift. To add a signal: append one line on an unused
slot, poke it through the existing helpers. Nothing else to maintain.

Counting coverage: analyzer signals (every gated
`signal!(self.recording, …)` poke) are set+counted+scope-tagged together.
Backend (30, 81) and runtime (50, 60, 70, 90) pokes are boolean-only
today — counter 0 and empty scope cells do not prove "never fired" for
those slots.

## INVARIANTS (the contract)

1. Slot index == byte offset for the classic plate; sections append after
   byte 256 (geometry in CONTEXT). `set_len` may only grow the file to its
   full 33536 bytes — set_len back to 256 would TRUNCATE the scope
   sections; never truncate, never create a fresh file to "reset" —
   accumulation is a feature, the counters and scope sections are the
   per-run view.
2. LOW half: constant-1 stores only. No arithmetic, no read-modify-write,
   no compiler-side clears. Slots 0/1 keep their build-status meaning.
3. HIGH half and scope sections: compiler-owned. Pass A zeroing happens
   before any poke (counters, then scope histogram + directory).
   Increments saturate at 255; changing saturating_add to wrapping add is
   a bug, not a fix. The runtime must never write bytes 128..33536.
4. One compiler instance per plate at a time. The counter increment is a
   non-atomic read-modify-write; two concurrent compiles in one CWD lose
   counts (booleans survive — constant stores are race-safe — counters do
   not). The harness is sequential; keep it that way or give each job its
   own CWD.
5. Analyzer pokes fire only when `self.recording` is true (the final
   post-fixpoint walk). Ungated pokes let the fixed-point loop inflate
   counts and will silently corrupt the shadow.
6. New signals: unused slots only, one line in trace_signals.txt (the
   build generates the consts and fails on collisions), and poke through
   the existing gated `signal!(self.recording, …)` sites so gating,
   counting, and scope tagging stay in one choke point.
7. Counting must never perturb codegen. The llvm/lock/ byte-identity gate
   is part of this contract, not an optional extra.
8. Determinism everywhere: BTreeMap/BTreeSet in the pipeline; never revert
   to hashed collections.
9. Scope context is recorded only during the final recording walk: block
   scopes (do / if branches / while body) get stable ids via the analyzer's
   scope_id() (deterministic first-visit order, root = 0, the While
   fixpoint reuses its body's id via the key map), and pokes pair with the
   register set by enter_scope/exit_scope. Ungated walks must never touch
   the register.
10. Scope ids beyond 254 fold into 255 (u8 plate limit — small scripts);
    widening it is a deliberate representation change, not a drive-by.

## FAILURE MODES TO GUARD AGAINST

- "Fixing" the sticky low half by truncating/zeroing it. Staleness is the
  price of crash-safety; the high half is the cure, not a reset.
- Treating 255 as data. It is the "many" sentinel; a count that matters
  beyond 254 needs a wider representation decided deliberately, not an
  accidental wrap.
- Adding a runtime writer to the high half (corrupts counters mid-compile
  via the MAP_SHARED mapping).
- Parallel compiles sharing one CWD (scrambles counters, mixes runs).
- Reading low 0/1 as per-run status on an aged plate: after a mixed
  history both are 1 forever ("ever ok" / "ever failed"). Per-run build
  status today is the stderr GLM_TRACE lines; making it per-run readable
  in the plate is a deliberate semantics change, not a drive-by.
- A poke outside the recording gate; a new signal colliding with a used
  slot; reverting BTree collections.
- Shrinking `set_len` back to 256 — it truncates the scope sections. The
  trace helpers only ever grow the file to its full length.
- Writing the scope register outside enter_scope/exit_scope, or during an
  ungated walk — silently misattributes WHERE a signal fired.

## DECODING RULES (how to read a plate)

- `byte[128+N] == k > 0`  → signal N fired exactly k times (or "many" at
  255) during the most recent compile, and `byte[N] == 1`.
- `byte[N] == 1 && byte[128+N] == 0` → N fired via a boolean-only path
  (backend 30/81, runtime 50/60/70/90) this run, or in some earlier run
  (sticky residue). For analyzer slots this is how you tell "not this
  case" from "reachable in this corpus".
- Scope cell (N, S) = k > 0 → signal N fired k times inside scope S this
  run (or "many" at 255); a signal's run total is the sum of its cells.
  Scope S exists this run iff its directory entry at 33024 + 2*S is not
  (0,0); the root is (0, 0xFF) and the directory doubles as the scope
  tree for the decoder.
- Scope drift: decode two runs of the same case and diff — the first
  diverging (signal, scope) cell localizes the behavior change; a changed
  directory entry means the scope structure itself moved.
- Two compiles of the same case must produce byte-identical plates. A
  difference is a determinism regression — treat it like lock drift.

## VERIFICATION (run all of it)

1. `cargo check --bin glm` clean, zero warnings; `cargo clippy --all-targets
   -- -D warnings` clean.
2. `cargo build --release`, then `lua lua/test.lua run` → 47/47 positive,
   28/28 negative, 47/47 lock byte-identity.
3. Manual plate check from the repo root: snapshot `xxd -a .glm_trace.bin`,
   compile one case (e.g. glm/cases/nested_homogeneous.lua) twice; the two
   post-compile snapshots must be byte-identical across the full 33536
   bytes (counters and scope sections reset per run), and the diff against
   the pre-compile snapshot must touch only bytes 128..33536 (sticky half
   unperturbed). Spot-check the implication `counter > 0 ⇒ boolean == 1`
   on every nonzero counter byte, and `scope cell > 0 ⇒ boolean == 1`
   likewise (`python3 plate.py` runs these contract checks for you).
