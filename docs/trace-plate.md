# TASK: Maintain the .glm_trace.bin plate (compile-run persistent debug data)

Any agent touching src/trace.rs, src/rt.rs, src/main.rs, or the analyzer's
signal path must uphold this contract. The plate is the persistent shadow of
the compile pipeline: its data representation is load-bearing for the planned
signal-driven state machine, so "it's just a debug file" is not a valid reason
to change it ad hoc.

## CONTEXT (verified state of the representation)

One file, ./.glm_trace.bin, 256 bytes, one byte per slot, slot index ==
byte offset (so `xxd -a .glm_trace.bin` reads it straight from the shell).
The file is never truncated and lives per working directory. Two halves:

- LOW half, bytes 0..128 — sticky signal booleans. Written ONLY by
  constant-1 stores: compiler via `compiler_trace_set` (src/trace.rs),
  runtime via `glm_trace_set` (src/rt.rs, MAP_SHARED over the same bytes).
  OR-semantics: once 1, stays 1. No wrap, no clear — `glm_trace_clear`
  exists but has zero callers.
- HIGH half, bytes 128..256 — per-run counter mirror. Byte 128+N counts
  trigger N in the MOST RECENT compile. Zeroed at compiler startup by
  `compiler_trace_reset_counts` (pass A, first statement of main), then
  incremented by `compiler_trace_count` with a saturating read-modify-write
  (pass B) — 255 means "many", it must never wrap.

Slot ownership (do not renumber, do not double-book):

| Slots      | Owner    | Meaning |
|------------|----------|---------|
| 0, 1       | compiler | compiled ok / build failed (EXPECT_BUILD_FAIL) |
| 10, 11     | analyzer | BIND_SCALAR / BIND_HEAP |
| 20         | analyzer | SHAPE_DROP |
| 21         | analyzer | SHAPE_CONFLICT_GUARD (elem_type_of_tbl Conflict guard) |
| 22         | analyzer | RECORD_PRESERVED (Record beats child_sites fast path) |
| 23         | analyzer | CHILD_FAST_PATH (multi-child coherence fast path) |
| 24         | analyzer | FALLBACK_RESOLVE (final match fallback) |
| 25         | analyzer | DECIDE_VISIT (decide() entered) |
| 26         | analyzer | JOIN_RETYPED (join_ty actually moved the type) |
| 30         | backend  | OFFLOAD_EMIT |
| 80         | analyzer | FAIL_ALIAS_UNION |
| 81         | backend  | FAIL_TYPE_CONFUSION |
| 50,60,70,90| runtime  | RT_ALLOC / RT_FREE / RT_SPARSE_UPGRADE / LEAK |
| 27-29, 31-49, 51-59, 61-69, 71-79, 82-89, 91-127 | free | allocate here |

Counting coverage: analyzer signals (everything through `Analyzer::trace`)
are set+counted together. Backend (30, 81) and runtime (50, 60, 70, 90)
pokes are boolean-only today — counter 0 does not prove "never fired" for
those slots.

## INVARIANTS (the contract)

1. Slot index == byte offset, 256 bytes total. `set_len` may only grow the
   file to 256; never truncate, never create a fresh file to "reset" —
   accumulation is a feature, the counters are the per-run view.
2. LOW half: constant-1 stores only. No arithmetic, no read-modify-write,
   no compiler-side clears. Slots 0/1 keep their build-status meaning.
3. HIGH half: compiler-owned. Pass A zeroing happens before any poke.
   Increments saturate at 255; changing saturating_add to wrapping add is
   a bug, not a fix. The runtime must never write bytes 128..256.
4. One compiler instance per plate at a time. The counter increment is a
   non-atomic read-modify-write; two concurrent compiles in one CWD lose
   counts (booleans survive — constant stores are race-safe — counters do
   not). The harness is sequential; keep it that way or give each job its
   own CWD.
5. Analyzer pokes fire only when `self.recording` is true (the final
   post-fixpoint walk). Ungated pokes let the fixed-point loop inflate
   counts and will silently corrupt the shadow.
6. New signals: unused slots only, named constants in src/trace.rs, and
   poke through the existing helpers (`self.trace` in the analyzer) so
   gating and counting stay in one choke point.
7. Counting must never perturb codegen. The llvm/lock/ byte-identity gate
   is part of this contract, not an optional extra.
8. Determinism everywhere: BTreeMap/BTreeSet in the pipeline; never revert
   to hashed collections.

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

## DECODING RULES (how to read a plate)

- `byte[128+N] == k > 0`  → signal N fired exactly k times (or "many" at
  255) during the most recent compile, and `byte[N] == 1`.
- `byte[N] == 1 && byte[128+N] == 0` → N fired via a boolean-only path
  (backend 30/81, runtime 50/60/70/90) this run, or in some earlier run
  (sticky residue). For analyzer slots this is how you tell "not this
  case" from "reachable in this corpus".
- Two compiles of the same case must produce byte-identical plates. A
  difference is a determinism regression — treat it like lock drift.

## VERIFICATION (run all of it)

1. `cargo check --bin glm` clean, zero warnings; `cargo clippy --all-targets
   -- -D warnings` clean.
2. `cargo build --release`, then `lua lua/test.lua run` → 47/47 positive,
   28/28 negative, 47/47 lock byte-identity.
3. Manual plate check from the repo root: snapshot `xxd -a .glm_trace.bin`,
   compile one case (e.g. glm/cases/nested_homogeneous.lua) twice; the two
   post-compile snapshots must be byte-identical (counters reset per run),
   and the diff against the pre-compile snapshot must touch only bytes
   128..256 (sticky half unperturbed). Spot-check the implication
   `counter > 0 ⇒ boolean == 1` on every nonzero counter byte.
