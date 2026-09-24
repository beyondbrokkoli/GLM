# Records and Memory — Baseline Comprehension Report

Frozen reference: commit `2380732` ("glm"), working tree clean.
Every claim below was verified two ways: against the source with
`file:line` citations, and against the binary
(`./target/release/glm`, clang `-O3`, linked against
`target/release/libglm_rt.a`) via ~30 probe programs run from a
scratch directory. Where the source and the binary disagree, the
binary wins and the divergence is called out.

Companion artifact: the constructor stress suite added under
`glm/cases/` (indexed in Appendix B). No source file was modified.

---

## A. Leak counter semantics

### A.1 What `t = nil` actually does

`t = nil` is resolved entirely at compile time. The runtime has no
operation for it — no drop queue, no reference count, no deferred
set. There are exactly three compile-time outcomes
(`src/lowerer.rs:125-135`):

1. **Eager free.** If shape analysis proved sole ownership of every
   alias root reachable from the name (`ShapeFacts::is_free`,
   `src/shape.rs:187-189`, computed by `Analyzer::drop_reference`,
   `src/shape.rs:675-701`), the lowerer emits
   `Instruction::TableFree` at that program point → a direct,
   synchronous `glm_tbl_free(ptr)` call in the emitted IR
   (`src/backend.rs:459-462`). This is *the* deallocation path of
   the whole dialect.
2. **Silent leak.** If ownership cannot be proven (the alias union
   trap exercised by `glm/cases/nil_free_alias_leak.lua`: `target`
   may be `a` or `b` after the if-join, so `drop_reference`'s
   sole-ownership scan over all scopes, `src/shape.rs:683-689`,
   fails), **no code is emitted for the drop at all**. The register
   is overwritten with `LoadNull` (`inttoptr i64 0 to ptr`,
   `src/backend.rs:164-166`) and the old pointer is orphaned. The
   memory stays live until process exit. "Deferred" is a misnomer —
   there is no later pass that picks it up.
3. **Compile-time rejection.** If the variable's static type is
   `Record` (not `Table`), `src/type_checker.rs:89-96` panics:
   `Type Error: 'nil' releases tables — 'r' is a Record<…>`. See
   Blind Spot BS-1: records cannot be dropped by any means.

Additionally, `Stmt::Do` block exit emits `TableFree` for block-local
variables of static type `Table(_)` — and only `Table(_)`
(`src/lowerer.rs:395-418`, type filter at `:408`). The top-level
chunk, `while`, and `if` never emit scope-exit frees; the OS reclaims
at exit.

### A.2 What the counter counts

`sys_alloc_count()` returns `ALLOC_COUNT`, an `AtomicUsize` with no
other reader (`src/rt.rs:27`, `:494-496`):

- **+1** per `glm_tbl_new` — the `GlmTable` *header* box only
  (`src/rt.rs:62`). It does **not** count element buffers (allocated
  lazily by `span_grow`, `src/rt.rs:256-301`), sparse maps, strings,
  or record headers any differently — a record is a `GlmTable` and
  counts the same (verified: `local r = {x:100, y:200}` → `1`).
- **−1** per `glm_tbl_free`, taken *before* the free logic runs, and
  once per recursive deep-free child
  (`src/rt.rs:406`, recursion at `:427`/`:434`).

So the counter is **live table headers**, i.e. allocations minus
drop-requests honored — not bytes, and not "the deferred set": it
also counts tables that will be (or were) freed by scope exit, and
it is **not monotonic** (decrements are real; verified: a standalone
`do`-block containing only a table prints `0`; the same block with
only a record prints `1`; the two blocks combined print `1` then
`1` — the record's +1 is permanent, the table block nets zero).

### A.3 The invariant, verdict by verdict

> "nil-free is a request; actual reclamation is deferred because
> aliasing makes zero-reference proof impossible; the counter
> measures the deferred set and participates in no liveness
> decision."

- "nil-free is a request" — **true but misleadingly put**. It is a
  *compile-time* request whose two outcomes are "honor now" or
  "refuse silently". Nothing is registered anywhere on refusal.
- "actual reclamation is deferred" — **false**. Reclamation is
  eager-or-never. The refused set is leaked until `exec` tears the
  address space down. There is no deferred mechanism in `rt.rs` —
  no queue, no arena, no mark bits, no background anything.
- "aliasing makes zero-reference proof impossible" — **true in
  spirit**: the proof is the compile-time sole-ownership scan
  (`src/shape.rs:683-689`), and it is deliberately conservative.
- "the counter measures the deferred set" — **false**. It measures
  live headers (A.2). The refused set is a strict subset of it and
  is not distinguishable at runtime.
- "participates in no liveness decision" — **true**. Nothing in the
  runtime or the emitted IR reads `ALLOC_COUNT` except
  `sys_alloc_count()` (verified by grep: three touch sites, one
  reader).

### A.4 Would a reclaiming `collectgarbage()` be sound today?

**A reclaimer: no — unsound.** Enumerated references the runtime
would still need from the "deferred" set:

1. **Live SSA registers / allocas.** The backend keeps table
   pointers in ordinary LLVM registers and `alloca`s
   (`%vN`, `%tsN.dst`; e.g. `src/backend.rs:205-210`). There are no
   stack maps, no shadow stack, no root set. A sweeper cannot tell a
   leaked pointer from a live one. Concrete case: in
   `nil_free_alias_leak.lua` the *programmer* can still make the
   union reach either `a` or `b` through another name; only the
   compiler lost track, and only statically.
2. **Aliased children under the deep-free heuristic.**
   `glm_tbl_free` recursively frees element words that "look like"
   pointers when bit 7 (`contains_tables`) is set, using a
   range/alignment guess instead of type information
   (`src/rt.rs:410-438`, `is_valid_ptr` at `:413-421`). A collector
   that handed out those same children as live would collide with
   this heuristic in both directions (double free, or free of a
   forged integer that happens to look valid — note records store
   arbitrary i64 payloads in the same slots).
3. **Half-freed nesting states.** Blind Spot BS-4 documents programs
   (record-with-inline-table-field) where the header is freed at
   block exit but the child is intentionally-not-deep-freed — the
   "leaked" child is the *only* copy; a collector co-freeing parents
   and children needs ownership edges the runtime does not record.
4. **Registers hidden behind `Move`/phi webs.** Loop-carried tables
   move through phi nodes (`src/lowerer.rs:284-298`); liveness is
   not tracked in any metadata the runtime can see.

**An observer: sound today, and already built.** Per the stated
design goal — *the collector's one job is to observe leaked memory
on demand, via syscall, when `collectgarbage()` is issued, and
nothing else* — the counter *is* the on-demand ledger:
`collectgarbage()` can lower to a `sys_alloc_count()`-style C-ABI
call (or an RSS/page-fault syscall like `mallinfo`/`/proc/self/statm`
for byte-level observation of the leaked set) with zero soundness
risk, because it reads bookkeeping and touches no objects. The
observed number has a precise meaning: live `GlmTable` headers never
reclaimed since process start (A.2). Any *reclaiming* step inside
that call would trip hazards 1-4 above and must not be attempted
before a real ownership model exists.

---

## B. First-touch typing

### B.1 Full trace of `local m = {} ; m[0] = {x: 1, name: "hello"}`

1. **Parse** (`src/parser.rs:351-404`). `{` peeks: not an
   `Identifier` → not a record → `Expr::TableCtor([])`
   (`:389-403`). The record on the RHS parses via the
   Identifier-`:` lookahead (`:359-367`) into
   `Expr::RecordCtor([("x", 1), ("name", "hello")])`.
2. **Site numbering** (`src/analysis.rs:44-52`). Both ctors get a
   site id in `sites` keyed by AST pointer.
3. **Shape fixpoint** (`src/shape.rs:212-265`). `local m = {}`
   binds `m` to `Tbl(Pending)` with alias set `{site_m}`
   (`src/shape.rs:576-607`: empty ctor, no elements → site stays
   `Pending`). The store `m[0] = {…}` walks `Stmt::IndexAssign`
   (`src/shape.rs:418-448`): value infers to
   `Record([("x", Int), ("name", Str)])` (`:608-624`, which also
   pins `site_elem[site_r] = Record(...)`), and because `m`'s type
   is `Tbl(_)|Pending`, `decide(site_m, Record([...}))` joins
   `Pending ⊔ Record = Record` into `site_elem[site_m]`
   (`:539-568`, `join_ty` Pending-absorb at `:44`).
4. **Element resolution** (`src/shape.rs:244-255`). Post-fixpoint,
   `site_m` is no longer `Pending`, so `elem_type_of_tbl` maps the
   `Record` Ty into `StaticType::Record([("x", Integer),
   ("name", String)])` (`:316-318`). Note `m` is now typed as
   *table of records* — `Table(Record(...))` — not as a record.
5. **Type check** (`src/type_checker.rs:125-153`). The store
   unifies `m`'s element `Unknown(id)` with the record type; the
   substitution is flushed back into `ShapeFacts::substitutions`
   (`:29-34`, `src/shape.rs:153`).
6. **Lower** (`src/lowerer.rs:141-204`). `m`'s `TableNew` used
   `elem = Unknown(id)` → `elem_size(Unknown) = 1` → a **1-byte
   i8 dummy buffer** (`src/backend.rs:27-35`; "never read or
   written"). The record literal lowers to
   `glm_tbl_new(esize=8, flags=0)` + positional `glm_tbl_set` at
   slots 0 and 1 **in field order** (`src/lowerer.rs:600-617`;
   header element forced to `Table(Integer)`, `:592`). The store
   `m[0] = r` ptrtoints the record pointer into `m`'s slot.
7. **Runtime** (verified in IR of the golden case). `m` is created
   `glm_tbl_new(i64 8, i8 0)` — **8-byte slots, not a 1-byte
   dummy**: the checker's `Unknown → Record` substitution is
   flushed by `resolve_all_scopes` (`src/type_checker.rs:29-34`)
   before the lowerer runs (pipeline order, `src/main.rs:24-31`),
   so `elem_of(m)` resolves to `Record` and `elem_size` gives 8.
   The 1-byte `Unknown` dummy (`src/backend.rs:32`) is emitted only
   for tables that receive no typed store anywhere — and those
   never allocate a buffer (`span_grow` fires on stores only), so
   the dummy is currently header-only. See BS-7 for the residual
   fragility.

### B.2 `m`'s type before the first store, and the int fallback's homes

Before any store, `m : Table(Unknown(id))` — a *type variable*, not
an integer. The "implicit integer element type" ghost is not one
default but a family of eager `→ Integer` collapses. Exhaustive
inventory:

| # | Site | What it does |
|---|------|--------------|
| F1 | `src/shape.rs:244` | `elems` vector initialized `vec![StaticType::Integer; n]` — the residual default if a site slips past classification |
| F2 | `src/shape.rs:319` | `elem_type_of_tbl`: `Int \| Pending => StaticType::Integer` — reachable for *child* sites of nested ctors that stayed `Pending` (e.g. `{{}}`) |
| F3 | `src/shape.rs:332` | `ty_to_static`: `Pending => Integer` — same collapse for scope-propagated types |
| F4 | `src/lowerer.rs:700` | record positional read: non-constant or out-of-range key → `.unwrap_or(StaticType::Integer)` |
| F5 | `src/lowerer.rs:592` | every record's IR header element forced to `Table(Integer)` (the i64-slot model) |
| F6 | `src/backend.rs:173` | `TableNew{is_record}` registers the record's register as `StaticType::Integer` in `reg_types` (drives cast selection; see BS-3) |
| F7 | `src/backend.rs:194,285,384` | record-typed registers in `TableGet`/`TableSet*` resolve element to `Integer` |
| F8 | `src/type_checker.rs:210` | empty-record fallback `fields.first()…unwrap_or(Integer)` — currently dead (the parser cannot produce an empty `RecordCtor`, F9) |
| F9 | `src/parser.rs:389-403` | `{}` is *syntactically* routed to `TableCtor` — the parse-level root of the whole ghost |
| F10 | `src/rt.rs:226-229` | runtime zero-fill on OOB read — the *value*-level face of the same "absence = integer zero" assumption |
| F11 | `src/backend.rs:15,32,160-162,519` | `Unknown` → i8/1-byte dummies (the one fallback that is *not* Integer; the runtime truth for never-touched tables) |

### B.3 Second touch

- **Different shape** (`m[1] = {y: 2, name: "w"}`): shape layer
  `join_ty` requires same field count and same names
  (`src/shape.rs:55-72`) → `Conflict` → compile panic
  `heterogeneous tables are not supported` (`src/shape.rs:283`).
  Verified.
- **Scalar** (`m[1] = 42`): `join_ty(Record, Int) → Conflict` →
  same panic. Verified.
- **Permuted field order** (`{name, x}` after `{x, name}`): shape's
  join is *order-insensitive by name* and would accept; the type
  checker's `unify` has no Record arm and demands exact equality
  (`src/type_checker.rs:399-434`) → compile panic
  `type conflict — Record<x:Integer, name:String> vs
  Record<name:String, x:Integer>` (`:429`). Verified. Two layers,
  two shape-equivalence rules; the strict one wins (see BS-2).
- **`{}` second touch**: `join_ty(Record, Tbl(Pending)) → Conflict`
  → same panic (`src/shape.rs:283`). An empty literal can never
  join a record-typed site. Verified.
- **Int vs Flt same key** (`{x:1}` then `{x:1.5}`): `join_ty(Int,
  Flt) → Conflict` → panic. Verified. Mixed types *within* one
  record are fine (`{x:1, y:2.5, flag:true, name:"s"}` round-trips
  exactly through the i64 slots: `1  2.5  true  s`).

### B.4 Branches that can observe the pre-first-touch state

1. **Read with no store anywhere** → compile panic
   `a table is read before it is ever given a value`
   (`src/shape.rs:248`; golden case `glm/cases/table_undecided.lua`).
2. **Read with a store anywhere later** → *accepted*; typing is
   flow-insensitive, so the read acquires the (later) store's type.
   `local m={}; print(m[0]); m[0]=5` compiles and prints `0` then
   `5`. If the later store is a record, the early print panics the
   *backend* (BS-6 cascade). Verified both.
3. **`#t` on a never-touched table** → `0`, no buffer ever
   allocated (`glm_tbl_len` on `len=0` header, `src/rt.rs:239-254`;
   golden `glm/cases/first_touch.lua` pins `#dead == 0`).
4. **Never-touched, never-read ctor** → `Unknown(id)` survives to
   the backend → 1-byte dummy (F11). No test observes the buffer.
5. **Loop fill** — `decide(site, Int)` at the first iterated store
   (`src/shape.rs:437-443`); the whole `int_tables*` corpus rides
   this path (Ghost Map).
6. **Alias joins of `Tbl(Pending)`** — `merge_table_scopes`
   (`src/shape.rs:21-36`) and if/while scope merges can carry
   `Pending` to the fixpoint end; the `first_touch.lua` golden
   exercises exactly this ("a dead pre-if `{}` adopts the element
   of the table that replaces it").

---

## C. Record indexing ground truth

### C.1 The base is 0 for tables AND records — the handoff premise is false

The brief's claim "records are 0-based while legacy tables are
1-based" is **wrong**. Both are 0-based, uniformly and
intentionally:

- Both constructors lower to identical positional loops starting at
  `i = 0` (`src/lowerer.rs:606-617` for records, `:669-680` for
  tables; both `LoadInt { val: i as i64 }` from `enumerate()`).
- The runtime indexes `data + index * esize` (`src/rt.rs:190`,
  `:230`) — raw C semantics, 0-based.
- Binary: `t={}; t[0]=42; t[1]=99; print(t[0], t[1])` → `42  99`;
  records `player[0]` → `x`. Plain-table slot 0 is as real as a
  record's.
- Intent: the README's headline pillar — "HARDWARE-ALIGNED
  0-INDEXING … GLM drops Lua's 1-indexing to map directly to
  physical C-ABI grids" — and `glm/showcase.lua` demonstrates
  `matrix[0]` with the comment "LuaJIT prints nil here!".

No 1-based remnant exists in the indexing pipeline (no `+1`
adjustment anywhere between parser and `glm_tbl_set`). The dialect
is uniformly 0-based; any user confusion is Lua-habit friction, not
a code decision. **This dialect does not have two bases, and no code
"decides the base" per kind — there is exactly one base, chosen at
the constructor loops and the runtime's raw offset math.**

### C.2 Positional reads

- `player[0]`, `player[1]`: constant integer keys resolve per-field
  types (`src/lowerer.rs:693-703`) and load through the i64 slot
  with a per-target-type cast (`src/backend.rs:218-250`). Works,
  golden-pinned.
- `player[2]` (past field count, 2-field record): **in bounds,
  returns `0`**. Two reasons stack: `span_grow` grows to
  `max(want, 2*len, 8)` (`src/rt.rs:266`) so the buffer has ≥8
  zeroed cells; and even a genuinely OOB dense read zero-fills the
  destination instead of leaving it (`src/rt.rs:226-229`).
  **No phantom stack read exists for out-of-bounds indices on real
  tables** — earlier claims of one are false. Verified: prints `0`.
  (The phantom read *does* exist through *null* tables — BS-9.)
- `player[-1]`: dense get rejects negative indices and zero-fills
  (`src/rt.rs:226`) → `0`. Sparse mode likewise (`:207-222`).
  Verified.
- **Dynamic index** (`local i=1; print(p[i])`): the lowerer falls
  back to `Integer` typing (F4) and prints the *raw slot bits* —
  for slot 1 holding a string pointer, that is the pointer value as
  a decimal integer (verified: prints `94231027159216`,
  ASLR-varying). Unchecked pointer disclosure; see BS-5.

### C.3 Positional writes

Writes go through `Stmt::IndexAssign` with **no record-specific
typing**: `check_index_base` returns the *first field's* type for
every index (`src/type_checker.rs:206-213`).

- `p[0] = 5` on `{x:Int, name:Str}` — checked against `Int` →
  compiles, works. Verified: `5  init`.
- `p[1] = "s"` — still checked against field 0's `Int` → compile
  panic `type conflict — Integer vs String`. Verified. (The
  *mechanism* is first-field typing, not per-index checking.)
- `p[1] = 5` — checked against `Int` → **compiles**, stores `5`
  into the string slot; any later `print(p[1])` inttoptrs `5` into
  a string pointer and **segfaults** (verified, exit 139). The
  compile-acceptance is pinned as a case; the segfault reproducer
  lives in BS-5 (a segfault leaves empty stderr, which the harness's
  `EXPECT_PANIC` pin matching cannot classify — noted in Appendix A).
- There is no field-name write syntax at all: the lexer has no `.`
  token (`src/lexer.rs`), so `t.f = v` does not parse. Records are
  write-once at construction, plus unchecked positional stores.

### C.4 Other record operations

- `print(record)` — slips past the checker's Table-only print gate
  (`src/type_checker.rs:189-193`; `Record` is not `Table`) and
  panics the backend: `records compile as tables, cannot be printed
  directly` (`src/backend.rs:520`). Compile-time panic, verified.
- `#record` — rejected: `'#' requires a table operand, got
  Record<…>` (`src/type_checker.rs:347-353`). Verified.
- `record == record` — passes the checker (`types_compatible`
  handles Records, `:453-453`), then fails clang: the backend
  compares the record registers as `i64` while they hold `ptr`s —
  `'%v0' defined with type 'ptr' but expected 'i64'`. Verified.
- `print(r[1])` where field 0 is a table — rejected: the checker
  types *every* index with field 0's type, so `r[1]` (String) is
  checker-typed `Table(Int)` and hits the print gate. Verified.
  The lowerer would have typed it correctly — another
  checker/lowerer desync (BS-2 family).

---

## Architectural Blind Spots

Findings the next implementation task must know about. None of
these were fixed; each is pinned by a case where the harness
supports pinning (Appendix B) and otherwise carries a minimal
reproducer here.

**BS-1 — Record immortality.** Records are heap `GlmTable`s
(+1 on the counter, verified) that cannot be dropped: `r = nil`
is a compile error (`src/type_checker.rs:89-96` requires
`StaticType::Table`), and the do-block exit free filters on
`Table(_)` only (`src/lowerer.rs:408`), so block-scoped records
leak unconditionally (verified: `1` vs the table control's `0`).
The only records that ever get freed are those retyped into
`Table(_)` by BS-4's bug. Reproducer:
`do local r = {x:1, name:"a"} end print(sys_alloc_count())` → `1`
(standalone table control → `0`; combined program → `1`,`1`).

**BS-2 — Shape-equivalence desync (permuted keys).** Three layers
disagree about what "same record shape" means: shape's `join_ty`
is order-insensitive by name (`src/shape.rs:55-72`), the checker's
`unify` is exact-equality order-sensitive with no Record-merge arm
(`src/type_checker.rs:399-434`), and the lowerer assigns slots in
parse order (`src/lowerer.rs:606-617`). Today the checker's
strictness masks the UB — `{x:…,name:…}` vs `{name:…,x:…}` into one
table fails to compile (pinned) — but the desync means any future
relaxation of the checker (or adoption of shape's join in the
checker) silently produces positional type confusion: slot 0 would
hold a string pointer while every consumer types it `Integer`.
The lowerer's per-field read typing (`:693-703`) reads the *joined*
site type's field order, which follows the first stored record.
Related: the checker types every record index as field 0's type
(`src/type_checker.rs:206-213`), making non-first fields of
table-led records unprintable (verified) — same desync family.

**BS-3 — Nested record coercion failure.** A record whose field is
a record fails to compile with invalid LLVM IR:
`'%v1' defined with type 'ptr' but expected 'i64'` (clang), for the
inline form `{inner: {x:1}}` *and* the named form
(`local inner = {x:1}; local r = {copy: inner}` — both verified).
Mechanism: record registers are typed `Integer` in `reg_types`
(`src/backend.rs:173`), so `TableSet`'s value-cast selection
(`src/backend.rs:404-407` reads `reg_types.get(value)`) sees
`Integer`, skips the `ptrtoint` arms (`:425-432`), and stores the
raw pointer into an `i64` alloca. Note for the fix blueprint: the
`TableGet` side already has the `Record` inttoptr arm
(`:237-243`); adding `Record` to the *cast-arm match* is not
sufficient — the value-type source (`reg_types` masquerade) must
change, or `TableSet`'s selection must use the lowerer's static
type.

**BS-4 — `child_sites` strips Record-ness → flagless deep-free
bypass.** A record with an *inline table* field,
`local b = {data: {1,2,3}}`: shape's `elem_type_of_tbl` prefers the
uniform-children fast path and returns `Table(Table(Int))`,
discarding the `Record` type entirely (`src/shape.rs:287-310`).
Consequences, all verified: (a) the lowerer sees a `Table`-typed
local, so do-block exit **does** free the record header
(`src/lowerer.rs:408` now matches) — Record identity lost;
(b) the `contains_tables` deep-free flag is computed from the
retyped element via the `StaticType::Record` match arm, which no
longer matches → `flags = 0` (verified in IR:
`glm_tbl_new(i64 8, i8 0)`) → the child table leaks
(`sys_alloc_count()` → `1`); (c) the record-with-identifier-table
form keeps its `Record` type (no child site for identifiers) and
therefore leaks the whole record instead. One syntax-variant
difference, two different leak shapes.

**BS-5 — Compile-accepted positional store, segfaulting read.**
`p[1] = 5` on `{x:Int, name:Str}` compiles (first-field typing,
BS-2) and later reads segfault:
```lua
local p = {x: 10, name: "init"}
p[1] = 5
print(p[1])   -- inttoptr i64 5 → glm_print_string(0x5) → SIGSEGV
```
The compile-acceptance is pinned green; the read is not pinnable
(segfault stderr is empty; `EXPECT_PANIC` matching requires
non-empty stderr text — harness limitation, Appendix A).
Same family: dynamic-index reads disclose raw pointer bits
(verified `94231027159216`; not pinnable — ASLR-nondeterministic).

**BS-6 — Backend `unreachable!()` on record-typed prints.**
`print(r)` passes the checker (print gate rejects `Table` only,
`src/type_checker.rs:189-193`) and panics the *compiler* at IR
generation (`src/backend.rs:520`). Reads of record-typed values
textually *before* the store that types them hit the same panic via
flow-insensitive typing (verified). Pinned as a build-fail case.

**BS-7 — Element size depends on substitution resolution order.**
The `Unknown → 1-byte` dummy (`src/backend.rs:32`) is real but only
reachable for tables that never receive a typed store — and those
never allocate an element buffer (`span_grow` fires on stores
only), so it is header-only today (verified: untouched table →
`glm_tbl_new(i64 1, i8 0)`, no other table calls). The reason
first-touch tables are sized correctly is *pipeline coupling*: the
checker's substitutions are flushed (`src/type_checker.rs:29-34`)
before the lowerer emits `TableNew` (`src/main.rs:24-31`). Any
future reordering of the pipeline, or any path that lowers a
`TableNew` before unification completes, would silently allocate
1-byte slots under 8-byte values. This is a fragility note, not a
live bug.

**BS-8 — Small divergences pinned for the record.**
- Duplicate keys: `{x:1, x:2}` silently becomes a 2-slot record
  (`1  2`; Lua semantics would be last-wins, length 1).
- `#t` is span capacity with floor 8, not element count:
  `m={}; m[0]=1; #m` → `8` (verified; `span_grow`
  `src/rt.rs:266`). Untouched `#t` → `0`.
- `{}` cannot join a record-typed table site (compile panic,
  verified) — the empty literal's ambiguity is resolved *against*
  records at the type layer too.
- `nil` in any expression position is rejected
  (`src/type_checker.rs:238-241`); `p[1] == nil` does not compile.
- Nested null-child store: `m[0][0] = 5` on a never-allocated row is
  a silent no-op (`src/rt.rs:134-136`) — and the companion read is
  worse, see BS-9.

**BS-9 — Null-table reads return uninitialized stack memory.**
`glm_tbl_get` early-returns on a null table **without** zero-filling
the destination (`src/rt.rs:201-203`: `if t.is_null() || dst.is_null()
{ return; }`), unlike the real-table OOB path, which zero-fills
(`:226-229`). A read through a never-allocated child row therefore
leaves the backend's destination `alloca` untouched and the loaded
value is whatever the stack held. Verified nondeterministically: the
same program printed `0` in one process and `140721637957568` (a
stack address) in another, depending on prior stack state. This is
the one place the "no phantom read" claim is false: absence reads
safely as zero for *out-of-bounds indices on real tables*, but as
*uninitialized memory* through *null tables*. Reproducer:
```lua
local m = {}
m[0][0] = 5        -- silent no-op into null row
print(m[0][0])     -- uninitialized stack read, value varies by run
```

---

## D. The Ghost Map — migration plan for the implicit-integer fallback

**Goal (future task):** remove the eager `Pending/Unknown →
Integer` collapses (F1-F4, F8) so that a table's element type is
always decided by a *store* (or an explicit annotation), never
assumed. **Do not execute from this task.**

### D.1 Ground rules

- The runtime needs a *concrete* `esize` per table at `TableNew`.
  Replacing the type-layer fallback therefore means either (a)
  keeping an explicit default at the lowering boundary (a
  *documented* default, not a scattered inference accident), or
  (b) deferring `TableNew` until first typed store (BS-7 shows the
  1-byte dummy is already the de-facto "no element type" state).
- The brief's suggested "Phase 2" (runtime-side lazy allocation
  sized by the stored value, `glm_tbl_set` growing per value type)
  is runtime-dynamic typing and conflicts with the static frontend:
  the backend emits `getelementptr inbounds {ety}` with a
  compile-time `ety` for dense fast-path stores
  (`src/backend.rs:332-343`) and the record model *requires* fixed
  8-byte slots. If buffer laziness is wanted, keep `esize` static
  and only defer the *allocation* (the dummy already does this).

### D.2 Dependent code and tests, classified

| Dependency | Mechanism (verified) | Class | What migration needs |
|---|---|---|---|
| `glm/cases/table_undecided.lua` | pins the read-before-value panic (`src/shape.rs:248`) — the one guard that *penalizes* pre-first-touch | SEMANTIC (a real user-facing guarantee: silent zero-reads are rejected) | Keep the panic; it survives fallback removal unchanged. |
| `glm/cases/first_touch.lua` | alias-carried first-touch decisions; `#dead == 0`; float unification | SEMANTIC (pins the *decision discipline*, not the int default) | Unaffected if decisions still flow through aliases; re-run to confirm. |
| `glm/cases/nil_free_alias_leak.lua` | `a[0] = 1` decides `Int` at the store | INERTIA (store-decided; the fallback never fires) | None expected. |
| `glm/cases/int_tables.lua`, `int_tables_gauntlet.lua` | loop fills decide `Int` at first iterated store; pinned exact arithmetic output | INERTIA (first touch is the store; fallback is unreachable in these programs) | None expected; the gauntlet is the regression net. |
| `glm/cases/table_len_int.lua` | `#5` rejection — not actually fallback-dependent (mis-attributed in earlier notes) | NONE | Exclude from the migration. |
| `glm/cases/table_identity.lua` | pointer comparison via `icmp ptr` (`src/backend.rs:632`) — element type never consulted (mis-attributed) | NONE | Exclude. |
| `glm/cases/table_undecided`-adjacent: any `{}` printed via `print(t[0])` with a later scalar store | flow-insensitive read typing (B.4.2) | INERTIA (behavior emerges from fixpoint, not from F2/F3 directly) | Preserve the flow-insensitive contract or the corpus prints change. |
| Fallback sites F2/F3 (`{{}}` nested-Pending children) | nested-empty ctors silently become `Table(Integer)` | INERTIA (no corpus case observes it) | Decide and pin: `{{}}` should either panic like `table_undecided` or stay `Table(Integer)` *by explicit rule*. |
| F4 record positional fallback | dynamic/OOB record reads type `Integer` | SEMANTIC-adjacent (BS-5: today it *discloses pointers*; the fallback is the bug's enabler) | Migration should replace with a per-site dynamic-key guard or a documented "dynamic record read = error". |
| `showcase.lua` / README contract | "tables behave as int grids" is the documented dialect face | SEMANTIC (user-facing) | If the default changes, it must change in docs + showcase together, one commit. |

### D.3 Recommended sequence (three strikes, one commit each, per brief)

1. **Canonical record slots** (fixes BS-2's latent confusion).
   Canonicalize field order at the parser (`src/parser.rs:369-388`).
   **Decision required:** alphabetical sort breaks the existing
   golden `nested_conflict_ctor` (`name` < `x` would move `"hero"`
   to slot 0 and flip the EXPECT to `hero	0`); first-occurrence
   order preserves every existing golden. Whatever is chosen must
   also align `unify` (give it a Record arm) with shape's
   name-based join so all three layers share one equivalence.
2. **Coercion unification** (BS-3). Fix the *value-type source*
   (record regs masquerading as `Integer` in `reg_types`,
   `src/backend.rs:173`) or select casts from the lowerer's static
   type. Then `{inner: {…}}` and `{copy: inner}` compile; the
   BS-3 build-fail pins flip to positive cases (each flip = one
   commit with its before/after pair).
3. **Lifecycle parity** (BS-1 + BS-4). Widen `t = nil` to Records
   (`src/type_checker.rs:89-96`), widen the block-exit filter to
   owned heap types (`src/lowerer.rs:408`), and preserve
   `Record`-ness in `elem_type_of_tbl`'s child path
   (`src/shape.rs:287-310`) so the deep-free flag is computed from
   the real field types. **Do not** add `String` to deep-free
   ownership: strings are interned `.rodata` globals
   (`src/backend.rs:129-143`), not owned allocations — freeing them
   is a new corruption bug. Verify each strike against
   `nil_free_*` goldens and the counter cases from Appendix B.

---

## Appendix A — Harness mechanics discovered while building the suite

- Pins: `-- EXPECT:` / `-- EXPECT_BUILD_FAIL:` / `-- EXPECT_PANIC:`
  (`lua/conf.lua` `parse_pins`). Positive cases are checked by
  whole-stdout equality *including when they declare no EXPECT
  pins* — any output without pins fails, so observation cases must
  pin their exact output. `-- BASELINE:` comments are invisible to
  the pin parser (the regex only captures `EXPECT[_A-Z]*` prefixes),
  so wrong-but-current files here carry **both**: a `-- BASELINE:`
  header explaining the wrongness and `-- EXPECT:` pins of the
  recorded current behavior. Nothing is sanctified that the header
  does not flag.
- `EXPECT_PANIC` requires non-empty stderr containing the pin text;
  a bare `SIGSEGV` (empty stderr) cannot be pinned — such
  reproducers live in this report (BS-5) instead of the corpus.
- New cases run with "(no lock)" notices by design; `llvm/lock/`
  rebaselining is a milestone-only operation (`lua/lock.lua`) and
  was **not** run — the codegen-freeze invariant for existing cases
  is untouched by this task (docs + cases only).

## Appendix B — The constructor stress suite (Deliverable 2 index)

All under `glm/cases/`; `BASELINE` marks wrong-but-current behavior
recorded deliberately (see Appendix A):

| File | Pins | Notes |
|---|---|---|
| `record_positional_slots.lua` | EXPECT | field order = slot order |
| `record_mixed_field_types.lua` | EXPECT | Int/Flt/Bool/Str in one record, i64-slot round-trip |
| `record_empty_literal_is_table.lua` | EXPECT | `{}` is the array-table (parse ambiguity root) |
| `record_positional_write_field0.lua` | EXPECT | positional write to slot 0 works |
| `record_in_table_first_touch_leak.lua` | EXPECT | record-in-table via store: outer freed at block exit, inner record leaks (BASELINE) |
| `record_duplicate_keys.lua` | EXPECT | duplicates become slots (BASELINE, diverges from Lua) |
| `record_positional_oob_zero_fill.lua` | EXPECT | `p[2]`, `p[1]`, `p[-1]` → 0/20/0 (BASELINE: zero-fill, floor-8 span) |
| `record_positional_write_wrong_slot_accepted.lua` | EXPECT | `p[1] = 5` compiles (BASELINE; segfault reproducer in BS-5) |
| `record_read_before_store_flow_insensitive.lua` | EXPECT | read before textual store prints 0 then 5 (BASELINE) |
| `record_counter_heap_allocated.lua` | EXPECT | value-semantics claim is false: records are heap refs (BASELINE) |
| `record_block_scope_leak.lua` | EXPECT | record leaks at block exit, table control nets zero (BASELINE; BS-1) |
| `record_with_table_field_inline.lua` | EXPECT | BS-4 flagless deep-free bypass: counter 1 (BASELINE) |
| `record_with_table_field_named.lua` | EXPECT | identifier-held table field; first-field print access (BASELINE) |
| `record_empty_join_conflict.lua` | BUILD_FAIL | `{}` cannot join a record site |
| `record_partial_overlap_conflict.lua` | BUILD_FAIL | `{x:1,name}` vs `{x:1}` |
| `record_int_flt_same_key_conflict.lua` | BUILD_FAIL | `{x:1}` vs `{x:1.5}` |
| `record_permuted_keys_conflict.lua` | BUILD_FAIL | checker rejects what shape would join (BS-2) |
| `record_nil_drop_rejected.lua` | BUILD_FAIL | BS-1 immortality gate |
| `record_positional_write_field0_typing.lua` | BUILD_FAIL | `p[1] = "s"` vs field-0 typing |
| `record_print_rejected.lua` | BUILD_FAIL | BS-6 backend panic |
| `record_len_rejected.lua` | BUILD_FAIL | `#record` |
| `record_nonfirst_field_print_rejected.lua` | BUILD_FAIL | first-field typing makes `r[1]` unprintable |
| `record_in_record_inline_ir_fail.lua` | BUILD_FAIL | BS-3 invalid IR (inline and named forms) |
| `nested_null_child_store_silent.lua` | EXPECT | null-row store is a silent no-op; counter 1; the read is unpin-nondeterministic (BASELINE; BS-9) |
| `table_len_capacity_floor.lua` | EXPECT | `#m` = 8 after one store; 0 untouched (BASELINE) |

Not pinnable, documented only: the BS-5 segfault read; the BS-5
dynamic-index pointer disclosure (ASLR-nondeterministic output).
