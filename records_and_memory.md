# Records and Memory — behavior map

> **CONSTRUCTOR CUT (2026-09-26):** populated constructors — `{e1, e2}`
> tables and `{k: v}` records — are REJECTED at parse ("Syntax Error:
> populated constructors are not supported"); only `{}` parses. The
> record machinery downstream (analyzer/checker/lowerer/backend arms,
> signals 22, 74, 75, 78, 82, 83, 85–88) is parked, not removed, and
> the record corpus cases are re-pinned as ctor-rejection guards. This
> map describes that parked machinery — it is the baseline the
> Lua-style constructor redesign (`[k] = v` / `k = v` entries) revives.
> Everything below is as-verified BEFORE the cut unless noted.

Verified against source (symbol citations below) and binary (probe
runs). Citations are file + symbol; line numbers churn. Rejection
texts are corpus-pinned verbatim (`Type Error:` / `Lifetime Error:`
prefixes). The record feature is an explicit draft: the `k: v`
constructor syntax is non-Lua and its edges are settling (BS-8), so
the type layers deliberately refuse mixed shapes/types rather than
model them — the holes (BS-5) are leaks in that strictness, not intent.

**Open issues:** BS-5 first-field typing (the memory-unsafe direction
is the one that compiles) · BS-6 records unprintable as whole values ·
BS-8 duplicate keys become slots; `#t` is span capacity · BS-9 reads
through null tables return uninitialized stack memory · BS-11 records
stored into tables never free. — All of these are now unreachable
behind the constructor cut (guarded by the record_* pins); they
revive, or die for good, with the Lua-style constructor redesign.

## A. Leak counter semantics

### A.1 `t = nil` and scope exit

`t = nil` is resolved entirely at compile time — the runtime has no
drop queue. Two outcomes (`IrLowerer::lower_stmt`, Assignment arm):

1. **Eager free.** Sole ownership of every alias root proved
   (`ShapeFacts::is_free` ← `Analyzer::drop_reference`) → lowerer
   emits `Instruction::TableFree` → synchronous `glm_tbl_free` call.
   This is *the* deallocation path of the dialect.
2. **Silent leak.** Ownership unprovable (the alias-union trap: after
   `if c then target = a else target = b end`, the sole-ownership scan
   fails) → NO code emitted for the drop; the register is overwritten
   with `LoadNull` and the allocation orphans until process exit.
   "Deferred" is a misnomer — nothing ever picks it up.

Either way the dropped name is poisoned for the rest of its scope:
any later table read/store/`#` through it is rejected —
`Lifetime Error: 't' may be nil here — table reads, stores, and '#'
through a possibly-nil name are rejected at compile time`. A drop
under an `if` poisons via the scope merge (glm rejects what Lua would
only maybe reject at runtime).

`Stmt::Do` block exit frees block-local heap values (tables and
records), but the decision is owned by shape analysis
(`Analyzer::decide_do_exit` → `ShapeFacts::do_exit_frees`): a heap
site frees iff no surviving binding holds it, ONE free per site
however many dying names alias it. A block-local aliasing a surviving
binding's table is rejected at compile time (pinned
`do_exit_alias_survives_rejected.lua`) — replacing the old silent
early free that left the surviving name dangling. Emission (post
join-fix, lowerer `Stmt::Do` arm): a site whose ctor dominates the
exit frees through its TableNew BIRTH REGISTER (`DO_EXIT_FREE_DEFREG`
— the header never moves, so the birth register holds it on every
path); a conditional ctor (if-arm / loop body) frees through the
carrier name's join register (`DO_EXIT_FREE_PHI`, null-safe) unless
that phi may alias a birth register freed at the same exit — then the
site leaks on some path instead (`DO_EXIT_JOIN_LEAK`, pinned
`do_exit_join_hazard_leak.lua`). A site already composted by a
nil-drop inside the block (loop merges resurrect its alias) is
skipped (`DO_EXIT_FREE_DROPPED` / `DROP_STALE_SITE`, pinned
`nil_free_stale_redrop.lua`). The deep-free flag
(bit 7) covers children written as inline constructors only; an
identifier-held child is owned by its own binding (flagging it would
double-free). Never extend deep-free to `String` (interned `.rodata`,
not owned). Top-level chunk, `while`, and `if` never emit scope-exit
frees; the OS reclaims at exit.

### A.2 What the counter counts

`sys_alloc_count()` returns `ALLOC_COUNT` (AtomicUsize, `rt.rs`):
**+1** per `glm_tbl_new` (header box only — not element buffers,
sparse maps, strings; a record counts the same), **−1** per
`glm_tbl_free` including each recursive deep-free child. So: live
table headers, not bytes, not a deferred set; not monotonic. The
process-exit leak report is a report, not reclamation.

### A.3 The invariant, verdict by verdict

- "nil-free is a request" — true, but it is a compile-time request:
  honor-now or refuse-silently. Nothing is registered on refusal.
- "reclamation is deferred" — **false**: eager-or-never.
- "aliasing makes zero-reference proof impossible" — true in spirit:
  the scan (`Analyzer::drop_reference`) is deliberately conservative.
- "the counter measures the deferred set" — **false**: it measures
  live headers (A.2); the refused set is an indistinguishable subset.
- "participates in no liveness decision" — true: only readers are
  `sys_alloc_count()` and the exit report.

### A.4 Would a reclaiming `collectgarbage()` be sound today?

**A reclaimer: no — unsound.** Hazards: (1) table pointers live in
ordinary SSA registers/allocas — no stack maps, no root set; (2) the
deep-free heuristic frees element words that "look like" pointers
(range/alignment guess; records store arbitrary i64 payloads in the
same slots); (3) no ownership edges parent↔child (BS-11 is the live
instance); (4) loop-carried tables move through phi webs with no
liveness metadata. **An observer: sound today** — lower
`collectgarbage()` to a `sys_alloc_count()`-style read (or
`/proc/self/statm` for bytes); any reclaiming step must wait for a
real ownership model.

## B. First-touch typing

### B.1 `local m = {} ; m[0] = {x: 1, name: "hello"}`

1. Parser: `{}` → `Expr::TableCtor` (not an Identifier before `:` →
   not a record); the RHS record parses via `Identifier:` lookahead,
   fields sorted alphabetically at construction (canonical layout
   `[("name",…), ("x",…)]`).
2. Site numbering: both ctors get dense site ids (`analysis.rs`).
3. Shape fixpoint: `m` binds `Tbl(Pending)` with alias set `{site_m}`;
   the store walks `Stmt::IndexAssign`, value infers
   `Record([("x",Int),("name",Str)])`, and `decide(site_m, Record)`
   joins `Pending ⊔ Record = Record` into `site_elem[site_m]`
   (`join_ty` Pending-absorb).
4. Element resolution: `elem_type_of_tbl` maps the Record Ty to
   `StaticType::Record`. `m` is now *table of records*, not a record.
5. Checker: store unifies `m`'s element `Unknown(id)` with the record
   type; substitution flushed back (`resolve_all_scopes`) before the
   lowerer runs (pipeline order, `main.rs`).
6. Lowerer/runtime: `m`'s `TableNew` gets 8-byte slots (substitution
   resolved by then); the record lowers to `glm_tbl_new(esize=8,
   flags=0)` + positional `glm_tbl_set` in canonical field order
   (header element forced `Table(Integer)`).

### B.2 The implicit-integer fallback inventory

| # | Site | What it does |
|---|------|--------------|
| F1 | `analyzer.rs` elems init | `vec![StaticType::Integer; n]` residual default |
| F2 | `elem_type_of_tbl` | `Int \| Pending => Integer` (nested-Pending children, e.g. `{{}}`) |
| F3 | `ty_to_static` | `Pending => Integer` (scope-propagated) |
| F4 | lowerer record read | non-constant/OOB key → `.unwrap_or(Integer)` |
| F5 | lowerer record ctor | header element forced `Table(Integer)` |
| F6 | backend `TableNew{is_record}` | record register typed Integer in `reg_types` |
| F7 | backend get/set | record-typed registers resolve element Integer |
| F8 | checker record fallback | `fields.first()…unwrap_or(Integer)` — dead (F9) |
| F9 | parser | `{}` syntactically routed to `TableCtor` — the root |
| F10 | rt zero-fill on OOB read | value-level "absence = integer zero" |
| F11 | backend Unknown | → i8/1-byte dummy (the one non-Integer fallback) |

### B.3 Second touch (deliberate draft-stage strictness)

Different shape / scalar / `{}` after a record / Int-vs-Flt on the same
key → `join_ty` Conflict → `Type Error: heterogeneous tables are not
supported`. Permuted field order joins fine (fields sorted at parse).
Mixed types *within* one record are fine (i64 slots round-trip).

### B.4 Branches observing pre-first-touch

Read with no store anywhere → rejected (`a table is read before it is
ever given a value`). Read with a later store → accepted
(flow-insensitive; early `print(m[0]); m[0]=5` prints `0` then `5`).
`#t` on never-touched → `0`. Never-touched ctor → 1-byte dummy (F11),
no path observes the buffer. Loop fill decides at the first iterated
store. Alias joins can carry `Pending` to fixpoint end (a dead pre-if
`{}` adopts the replacing table's element).

## C. Record indexing ground truth

### C.1 The base is 0 for tables AND records

Uniformly, intentionally: ctor loops enumerate from 0 (records and
tables alike), the runtime indexes `data + index*esize`, binary
`t={}; t[0]=42` and `player[0]` both work. No `+1` exists anywhere
between parser and `glm_tbl_set`. README pillar: "HARDWARE-ALIGNED
0-INDEXING". There is exactly one base, chosen at the ctor loops and
the runtime's offset math — no per-kind decision exists.

### C.2 Positional reads

Constant keys resolve per-field types (lowerer); past-field-count
reads are in-bounds and return `0` (span_grow floor `max(want, 2*len,
8)` + OOB zero-fill); negative → `0`. Dynamic index falls back to F4
and prints raw slot bits — for a string slot that is pointer
disclosure (ASLR-varying decimal). No phantom stack read exists for
OOB on real tables; through *null* tables it does (BS-9).

### C.3 Positional writes

No record-specific typing: `check_index_base` returns field 0's type
for EVERY index. Field 0 = alphabetically-first. `p[0] = "renamed"`
on `{x:10, name:"init"}` compiles (slot 0 is name:Str); `p[1] = 5` is
rejected (`Type Error: type conflict — String vs Integer`); `p[1] =
"s"` compiles but stores a string pointer into the x:Int slot (BS-5).
There is no field-name write syntax at all — the lexer has no `.`
token; records are write-once at construction plus positional stores
gated by the first-field rule.

### C.4 Other record operations

- `print(record)` — passes the checker's Table-only print gate,
  rejected at build: `Type Error: records compile as tables, cannot be
  printed directly` (BS-6). Reads textually before the typing store
  hit it too (flow-insensitive).
- `#record` — rejected: `'#' requires a table operand, got Record<…>`.
- `record == record` — passes the checker, fails clang: compares
  ptr-holding registers as i64 (`'%v0' defined with type 'ptr' but
  expected 'i64'`). Store path has record-aware coercion; compare has
  none.
- `print(r[1])` where field 0 is a table — checker types every index
  with field 0's type → print gate rejects. Lowerer would have typed
  it correctly — checker/lowerer desync.

## Architectural Blind Spots

Minimal reproducers; plate fingerprints in documentation.md §1.4.

**BS-5 — First-field typing on positional writes.**
```lua
local p = { x: 10, name: "init" }  -- canonical order: [name:Str, x:Int]
p[1] = "s"    -- checked against field 0 (Str) → compiles; stores a
              -- string pointer into the x:Int slot
print(p[1])   -- checker types the read Str; backend casts through F4
              -- Integer typing and prints raw pointer bits (ASLR)
```
The mirror write (`p[1] = 5`) is rejected — the unsound direction is
exactly the one that compiles. Same family: dynamic-index reads
disclose pointer bits.

**BS-6 — Records cannot be printed (build-time rejection).** See C.4.

**BS-7 — Element size depends on substitution resolution order.** The
`Unknown → 1-byte` dummy is reachable only for tables that never
receive a typed store — and those never allocate a buffer
(`span_grow` fires on stores), so it is header-only today. Correct
sizing of first-touch tables is *pipeline coupling*: the checker's
substitutions must flush before the lowerer emits `TableNew`. Any
reordering silently allocates 1-byte slots under 8-byte values.
Fragility note, not a live bug.

**BS-8 — Small divergences kept for the record.**
- Duplicate keys: `{x:1, x:2}` silently becomes a 2-slot record
  (`1  2`; Lua would be last-wins, length 1).
- `#t` is span capacity with floor 8, not count: `m={}; m[0]=1; #m`
  → `8`. Untouched `#t` → `0`.
- `{}` cannot join a record-typed site (rejection) — the empty
  literal's ambiguity resolves *against* records at the type layer.
- `nil` in any expression position is rejected; `p[1] == nil` does
  not compile.
- Nested null-child store: `m[0][0] = 5` on a never-allocated row is
  a silent no-op (`glm_tbl_set` null guard) — see BS-9 for the read.

**BS-9 — Null-table reads return uninitialized stack memory.**
`glm_tbl_get` early-returns on a null table WITHOUT zero-filling the
destination (unlike the real-table OOB path, which zero-fills), so
the backend's destination alloca holds whatever the stack held —
same program printed `0` one run, a stack address the next.
```lua
local m = {}
m[0][0] = 5        -- silent no-op into null row
print(m[0][0])     -- uninitialized stack read, varies by run
```

**BS-11 — Records stored into tables never free.** A record that
entered a table via a store does not free when the table does: the
deep-free flag has no ownership edge for stored values (an anonymous
record stored into `m[0]` is only reachable through `m`, but a named
one stored the same way is owned elsewhere — the flag cannot
distinguish). Needs a real ownership model, not a flag tweak.
```lua
do
  local m = {}
  m[0] = { x: 1, name: "a" }
end
print(sys_alloc_count())   -- 1: the stored record leaked
```

## D. The Ghost Map — migration plan for the implicit-integer fallback

**Goal (future task):** remove the eager `Pending/Unknown → Integer`
collapses (F1-F4, F8) so element type is always decided by a store or
annotation, never assumed. **Do not execute from this task.**

Ground rules: the runtime needs a concrete `esize` per `TableNew`, so
fallback removal means either (a) an explicit, documented default at
the lowering boundary, or (b) deferring `TableNew` to first typed
store (BS-7 shows the 1-byte dummy is already the de-facto "no
element type" state). Runtime-side lazy typing by stored value
conflicts with the static frontend (compile-time `ety` in the dense
GEP, records require fixed 8-byte slots) — keep `esize` static, defer
only the allocation.

| Behavior (verified) | Class | Migration need |
|---|---|---|
| read-before-value rejection | SEMANTIC (user-facing guarantee) | keep, survives unchanged |
| decisions via aliases/if-joins; dead pre-if `{}` adopts; `#` untouched = 0; float unification | SEMANTIC | unaffected if decisions still flow through aliases; re-verify after rework |
| alias-union drop trap (`a[0]=1` decides Int at the store) | INERTIA | none expected |
| loop-filled integer tables | INERTIA | drift here = migration damage |
| `#5` rejection | NONE (mis-attributed) | exclude |
| table equality via pointer compare | NONE (element type never consulted) | exclude |
| flow-insensitive read typing (`0` then `5`) | INERTIA | preserve the contract or outputs change |
| `{{}}` children silently `Table(Integer)` (F2/F3) | INERTIA | decide: reject like the undecided read, or make `Table(Integer)` an explicit rule |
| F4 dynamic/OOB record reads typed Integer | SEMANTIC-adjacent (BS-5 enabler) | per-site dynamic-key guard, or documented "dynamic record read = error" |
| showcase/README "int grids" face | SEMANTIC | default change ships with docs + showcase in one commit |
