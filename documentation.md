## 1. Trace signals

### 1.1 The plate

One compile writes `./.glm_trace.bin` — deterministic, crash-safe,
slot index == byte offset. Sections:

| bytes | section |
|---|---|
| 0..128 | sticky booleans ("ever fired, any run") |
| 128..256 | per-run saturating counters (255 = "many") |
| 256..33024 | scope histogram: cell (signal, scope) = count |
| 33024..33536 | scope directory: (depth, parent) per scope id |
| 33536..49928 | chronology ring: 8192 × (slot, scope) in fire order |

The runtime sidecar `./glm_rt_trace.bin` is 256 bytes, sticky-only.

```
rm .glm_trace.bin .glm_rt_trace.bin    # isolate a run
target/release/glm case.lua            # compile (writes the plate)
python3 plate.py --fired               # one line: slot:NAME(count)[scopes]
./glm_out                              # run; then read the sidecar
python3 plate.py                       # verbose: scopes, chronology, checks
cp .glm_trace.bin good.bin             # baseline … change … recompile
python3 plate.py good.bin bad.bin      # diff: first divergence
```

Hard rules (violations break the machine):

- Two compiles of one program → byte-identical plate. Any diff is a bug.
- New signals: unused slots only, one line in `trace_signals.txt`
  (the build fails on collisions). Never renumber, never double-book.
- Analyzer pokes only through the gated `signal!(self.recording, …)`;
  convergence-only movement through `Analyzer::probe`.
- Scope context only via enter_scope/exit_scope during the recording
  walk. Parser/checker pokes are deliberately scope-less (0xFF).
- Counting must never perturb codegen (IR identical, tracing on/off).
- BTreeMap/BTreeSet everywhere in the pipeline; never hashed collections.
- The runtime never writes bytes ≥ 128. Compiles in one CWD stay sequential.
- The file only ever grows to full length; truncating to "reset" destroys
  the scope sections. Staleness is the price of crash-safety; the high
  half is the per-run cure.

Reading rules: `counter > 0 ⇒ boolean == 1`; sticky 0/1 mean "ever",
not "this run" (per-run truth is the high half + stderr GLM_TRACE
lines); 255 is the "many" sentinel, never data. `python3 plate.py`
runs these contract checks for you.

### 1.2 Pipeline coverage

| pass | signals | scope-tagged |
|---|---|---|
| parser | 69, 83, 84 | no (runs before the scope walk) |
| shape analyzer | 2–9, 31–49, 51–59, 61–68, 80, 89, 91–125 | yes |
| type checker | 73, 76, 77 | no (analyzer owns the ids) |
| lowerer | 5–7 (do-exit emission), 72 | 5–7 root scope; 72 scope 0 on bail |
| backend | 30, 81 | boolean-only |
| runtime | 50, 60, 70, 90 (sidecar) | boolean-only |
| build status | 0, 1 | boolean-only |

The four GHOST_BAIL slots (69 parser, 68 shape, 73 checker, 72 lowerer)
name which pass poisoned a block; the scope cell names where, the
chronology names when.

### 1.3 Signal table

Status: **(conv)** = convergence-only, flushes one mark at fixpoint
exit (never fires on the recording walk). **(dead)** = cannot fire
under current wiring; a fire means the analyzer structure changed —
treat as alarm, not noise.

Build status
- 0 COMPILED — compile+link succeeded.
- 1 BUILD_FAIL — compile failed (EXPECT_BUILD_FAIL); the panic hook
  also sets it before any abort.

Do-exit ownership (the scope-exit face of the `t = nil` proof)
- 2 DO_EXIT_FREE_SITE — heap site proved solely owned by the dying
  do-block; one free handed to the lowerer. Trigger: `do local t = {} end`.
- 3 DO_EXIT_FREE_SHARED — site held by several dying bindings; deduped
  to one free. Trigger: `do local c = {}; local b = c end`.
- 4 DO_EXIT_ALIAS_SURVIVES — block-local aliases a site owned outside
  the block; rejected at compile time (was a silent early free / UAF).
- 5 DO_EXIT_FREE_DEFREG — lowerer freed the site through its TableNew
  birth register (ctor dominating the exit; the header never moves, so
  the birth register holds it on every path — the join-phi-proof fix).
- 6 DO_EXIT_FREE_PHI — lowerer freed a conditional site (ctor in an
  if-arm / loop body) through the carrier name's join register: header
  or null, both free-safe operands.
- 7 DO_EXIT_JOIN_LEAK — lowerer refused a free: the only sound register
  (a join phi) may alias a birth register freed at the same exit;
  bounded leak chosen over double free (same trade FAIL_ALIAS_UNION
  makes for `t = nil`).
- 8 DO_EXIT_FREE_DROPPED — do-exit skipped a dying site: a nil-drop
  inside the block already composted it (loop merges resurrect the
  alias; the header is dead at runtime).
- 9 DROP_STALE_SITE — nil-drop refused: sole ownership proved, but the
  site was already composted by an earlier drop (the killed-sites set).

Binding & statements
- 10 BIND_SCALAR — scalar (or nil/bare-local filler) binding.
- 11 BIND_HEAP — constructor binding (table/record).
- 31 STMT_ASSIGN_NIL — `t = nil` walk entry.
- 32 STMT_ASSIGN_TBL — table-typed assignment.
- 33 STMT_ASSIGN_TBL_VALID — its incoming-alias join step.
- 34 STMT_ASSIGN_TBL_SCALAR — scalar incoming to a table name.
- 35 STMT_ASSIGN_TBL_SCALAR_VALID — that scalar propagated to aliases.
- 36 STMT_ASSIGN_RESOLVED — assignment found its declaring scope.
- 37 STMT_IDX_NESTED — `t[i][j] = v` unwrapping loop iteration.
- 38 STMT_IDX_BASE_TBL — index-assign base is table-typed.
- 39 STMT_IDX_VALID_ALIAS — store decided a base alias site.
- 40 STMT_IDX_CHECK_THRESH — key threshold check ran.
- 41 STMT_WHILE_FILL — fill-loop conversion candidate detected.
- 42 STMT_WHILE_STABLE — while scope fixpoint reached stability.
- 43 STMT_IF / 44 STMT_DO / 45 STMT_PRINT — statement dispatch.
- 46 MUT_ASSIGN / 47 MUT_IF / 48 MUT_THEN_ASSIGN / 49 MUT_ELSE_ASSIGN
  — collect_mutated_names census (fill-loop safety).
- 19 FILL_LOOP_DENSE — table proven densely filled by a counted loop.

Drop & lifetime guards
- 20 SHAPE_DROP — sole-ownership drop proved (shadowing or `t = nil`).
- 80 FAIL_ALIAS_UNION — drop refused: alias union not provable (leak).

Lattice: infer / join / decide
- 25 DECIDE_VISIT — decide() entered.
- 65 DECIDE_CONFLICT — decide() hit an already-Conflict site (frozen).
- 26 JOIN_RETYPED **(conv)** — join_ty moved a site's type.
- 66 DECIDE_UPDATE **(conv)** — decide() retyped a scope alias.
- 67 DECIDE_UPDATE_CHANGED **(conv)** — that retype left Pending.
- 103 INFER_INT / 104 INFER_FLT / 105 INFER_BOOL / 106 INFER_STR /
  107 INFER_NIL — literal typing.
- 119 INFER_IDENT — identifier typing.
- 120 INFER_BINOP_ARITH / 121 INFER_BINOP_OTHER — binop typing.
- 122 INFER_UNOP_NEG / 123 INFER_UNOP_NOT / 124 INFER_UNOP_LEN.
- 125 INFER_SYSALLOC — `sys_alloc_count()` types Int.
- 108 INFER_TBL_CHILD — ctor element registered as child site.
- 109 INFER_TBL_FIRST / 112 INFER_TBL_MATCH / 110 INFER_TBL_MISMATCH
  — ctor element scan.
- 111 INFER_TBL_CONFLICT **(conv)** — heterogeneous ctor flagged.
- 113 INFER_TBL_RESOLVED / 114 INFER_TBL_PENDING — ctor exit state.
- 115 INFER_REC_CHILD **(dead: record machinery removed)** —
  was: record field holds a table (child site).
- 116 INFER_IDX_BAD_KEY / 117 INFER_IDX_BAD_OBJ / 118 INFER_IDX_VALID
  — index typing (117 fires on post-drop reads).
- 59 RESOLVE_FOUND — name resolution hit.

Resolution (post-fixpoint)
- 27 ANALYZE_MISSING_VALUE — read-before-value rejection.
- 28 ANALYZE_PENDING — site never decided → Unknown.
- 29 ANALYZE_RESOLVED — site classified.
- 21 SHAPE_CONFLICT_GUARD — Conflict guard in elem_type_of_tbl.
- 22 RECORD_PRESERVED **(dead: record machinery removed)** —
  nothing constructs records; a fire means a zombie arm came back.
- 23 CHILD_FAST_PATH — multi-child coherence path taken.
- 24 FALLBACK_RESOLVE — final match fallback taken.
- 91 ELEM_CHILD_CONFLICT **(dead)** — parent conflicts first.
- 92 ELEM_CHILD_FIRST / 94 ELEM_CHILD_MATCH / 93 ELEM_CHILD_MISMATCH
  **(93 dead: ctor-time compare subsumes it)** / 95 ELEM_CHILD_UNIFORM
  — child uniformity scan.
- 96 ELEM_FALLBACK_TBL / 97 ELEM_FALLBACK_REC **(dead: early Record
  guard returns first)** / 98 ELEM_FALLBACK_INT / 99 ELEM_FALLBACK_FLT
  / 100 ELEM_FALLBACK_BOOL / 101 ELEM_FALLBACK_STR / 102
  ELEM_FALLBACK_CONFLICT **(dead: early Conflict guard returns first)**.
- 51 TY_STATIC_INT / 52 TY_STATIC_PENDING / 53 TY_STATIC_FLT /
  54 TY_STATIC_BOOL / 55 TY_STATIC_STR / 56 TY_STATIC_TBL /
  57 TY_STATIC_REC **(dead: constructor cut)** / 58 TY_STATIC_CONFLICT
  **(dead: join_ty flattens Tbl(Conflict) before resolution sees it)**
  — Ty→StaticType.

Constructor census (Lua-style constructor landed: positional entries
fill slots 0..n-1, `{[k] = v}` takes constant integer slots, duplicate
slots/named keys/dynamic keys are parse errors)
- 82 PARSE_REC_CTOR **(dead: record machinery removed; the `{k: v}`
  spelling is a plain syntax error)** / 83 PARSE_TBL_CTOR — populated
  literal parsed / 84 PARSE_TBL_EMPTY — `{}` parsed (Pending/F9 root).
- 85 REC_CTOR / 86 REC_FIELD / 87 REC_NESTED **(dead: record machinery
  removed)** — were: record sites/fields/nesting at inference.
- 88 STMT_IDX_REC_VALUE **(dead: record machinery removed)** — was the
  BS-11 enabler.
- 89 STMT_IDX_TBL_VALUE — table stored into a table (deep-free edge).

Checker (scope-less by design)
- 73 GHOST_BAIL_CHECKER — first checker error poisons the block.
- 74 CHK_IDX_REC_FIELD0 **(dead: record machinery removed)** —
  was the BS-5 marker.
- 75 CHK_REC_EQ **(dead: record machinery removed)**.
- 76 CHK_UNIFY — Unknown type variable bound.
- 77 CHK_NIL_EXPR — nil in expression position.
- 78 CHK_PRINT_REC **(dead: record machinery removed)**.

Analyzer use-checks
- 12 CHK_TBL_IDENT — table-use check on an identifier.
- 13 CHK_TBL_NIL — possibly-nil guard (the `t = nil` poisoning).
- 14 CHK_USE_TBL / 15 CHK_USE_REC **(dead: record machinery
  removed)** / 16 CHK_USE_IDX /
  17 CHK_USE_UNOP_LEN / 18 CHK_USE_BINOP — check_uses dispatch.

Key thresholds
- 61 THRESH_INT — constant integer key.
- 62 THRESH_BOUNDS — key ≥ i64::MAX/8, rejected statically.
- 63 THRESH_SPARSE — key > 100_000, sparse verdict joined.
- 64 THRESH_SPARSE_ALIAS — verdict applied to an alias site.

Ghost bails
- 68 GHOST_BAIL — shape walk: block poisoned, siblings continue.
- 69 GHOST_BAIL_PARSER — syntax error, rest of file skipped.
- 72 GHOST_BAIL_LOWERER — first lower error skips the rest of the file
  (half-built SSA cannot resume); bail tagged scope 0.

Backend / runtime (boolean-only)
- 30 OFFLOAD_EMIT — offload emission.
- 81 FAIL_TYPE_CONFUSION — backend type confusion.
- 50 RT_ALLOC / 60 RT_FREE / 70 RT_SPARSE_UPGRADE — runtime sidecar.
- 90 FAIL_LEAK_DETECTED — nonzero ALLOC_COUNT at process exit.

Free slots (book nothing here without checking the file first):
71, 79, 126–127. The record family (15, 22, 57, 74, 75, 78, 82,
85–88, 97, 115) is dead with the machinery REMOVED — permanently
retired, free for reuse. Still-alive-alarm dead slots: 58, 91, 93,
102 (a fire means the analyzer structure changed). 83 revived with the
Lua-style constructor.

### 1.4 Pinned bug fingerprints

Each open bug is a mapped divergence: a distinct plate signature on
its pinned case. A refactor that moves one shows up as a delta there.

| case (glm/cases/) | fingerprint |
|---|---|
| nested_null_child_store_silent (BS-8/9) | STMT_IDX_NESTED(1) + ELEM_FALLBACK_TBL(1) |
| do_exit_alias_survives_rejected (contained) | DO_EXIT_ALIAS_SURVIVES + GHOST_BAIL |
| do_exit_join_hazard_leak (contained leak) | DO_EXIT_FREE_SITE(2) + DO_EXIT_FREE_DEFREG(1) + DO_EXIT_JOIN_LEAK(1) |
| nil_free_stale_redrop (killed-site proof) | SHAPE_DROP(1) + DROP_STALE_SITE(2) |
| record_* colon guards (9 files) | GHOST_BAIL_PARSER(1), nothing else — the `{k: v}` parse rejection is the pin (the record signals are retired with the machinery) |
| ctor_mixed/nested_mixed/scalar_table_mix/int_float_mix | INFER_TBL_MISMATCH(1) + INFER_TBL_CONFLICT(1) + SHAPE_CONFLICT_GUARD(1) — the heterogeneous refusal fingerprint |
| ctor_named_key/dup_index/dyn_key_rejected | GHOST_BAIL_PARSER(1) — parse-level, exactly the record_* shape |
| ctor_in_table_leak (BS-11 successor) | STMT_IDX_TBL_VALUE(1); sys_alloc_count prints 1 — the bounded stored-ctor leak, pinned knowingly |

Fixed-by-refactor (kept as regression pins):
`do_exit_alias_double_free_crash` — DO_EXIT_FREE_SITE + DO_EXIT_
FREE_SHARED + DO_EXIT_FREE_DEFREG, freed once, no abort.
`do_exit_alias_join_double_free` (the do-exit residual) — DO_EXIT_
FREE_SITE(2) + DO_EXIT_FREE_SHARED(1) + DO_EXIT_FREE_DEFREG(2): both
join inputs freed through their birth registers, the phi untouched,
sys_alloc_count() = 0.
`do_exit_join_phi_free` — DO_EXIT_FREE_SITE(1) + DO_EXIT_FREE_PHI(1):
conditional site freed through the carrier's join register.
`nil_free_lifecycle` (loop-drop sub-case) — DO_EXIT_FREE_DROPPED(1)
+ DROP_STALE_SITE(1) among its 6 defreg frees: the killed-sites set
refusing what the loop merge resurrected.

---

## 2. Runtime

MemoryLayout: GlmTable
A table value is one machine word — a pointer to a stable #[repr(C)] header.
Field layout (offset: type):
  data@0:       *mut u8   — the element buffer (never moves the header)
  len@8:        i64       — the zeroed, addressable span (doubling watermark)
  reserve@16:   usize     — 0 = malloc world; nonzero = PROT_NONE VA reservation
  esize@24:     usize     — element size: 8 for int/float/str/table, 1 for bool
  mode@32:      TableMode — 0 = Dense (flat buffer), 1 = Sparse (HashMap)
  contains_tbl@33: u8     — 1 = elements include nested tables (deep-free flag)
  sparse_map@40: *mut HashMap — opaque pointer when mode == Sparse
Total: 48 bytes (6 machine words).

THE ALIAS INVARIANT: the header NEVER moves. Only the data buffer does.
Every live copy of a table value points at the header, so growth may relocate
the buffer freely, table values stay plain SSA ptrs, and growth never invalidates
live table values. This is the entire alias story.

ALLOC_COUNT — Global live-allocation tracker: incremented on each `glm_tbl_new`,
decremented on each `glm_tbl_free`. Exposed via `sys_alloc_count()`
to observe memory leaks at runtime.

[glm_tbl_new]
# Safety
`esize` is 1 or 8 (the checker-pinned element sizes).
`flags` is a packed byte: bit 0 = mode (0=Dense, 1=Sparse), bit 7 = contains_tables.

[glm_tbl_grow]
# Safety
`t` live from glm_tbl_new; `idx` non-negative, non-overflowing.

[glm_tbl_reserve]
# Safety
`t` live from glm_tbl_new; on return the span covers `n` cells.

[upgrade_to_sparse]
# Safety
`t` is a live, mutable pointer from `glm_tbl_new`; `t.data` points
to a valid buffer of at least `t.len * t.esize` bytes when mode == Dense.

[glm_tbl_set]
# Safety
`t` live from glm_tbl_new; `val` points to `esize` bytes of data.

[glm_tbl_get]
# Safety
`t` live from glm_tbl_new; `dst` points to a caller-allocated slot.

[glm_tbl_len]
# Safety
`t` live from glm_tbl_new.

[glm_tbl_free]
# Safety
`t` live from glm_tbl_new, or null.

[glm_print_string]
# Safety
`val` NUL-terminated and readable through the terminator.

[sys_alloc_count]
Return the current number of live table allocations.
Incremented on `glm_tbl_new`, decremented on `glm_tbl_free`.
