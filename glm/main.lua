-- main.lua — "The Gauntlet" · long-run calibration
-- Strict subset: integers, tables, local, while, +, -, <, *
-- Phases A–M: the fill-loop wing (EC/HR calibration).
-- Phases N–Z: the memory wing — workload shapes for the two-world
--   runtime (malloc world below 1 MiB, PROT_NONE/mprotect reservation
--   above it — src/rt.rs) and the future per-site layout classifier:
--   chess validation (N), interleated growth (O), sparse graduation
--   (Q), renderer churn (R), UI relayout with aliases (U), z-buffer
--   giant fill (Z). GLM_VM=off A/Bs the runtime worlds on one binary.

-- PHASE A — The Stride
-- Shape: Non-unit induction step (+2). The loop writes only to even indices.
-- The capacity contract guarantees bounds up to `pa_lim`, while odd slots
-- remain implicitly 0. Tests whether sparse writes correctly avoid
-- corrupting or misallocating skipped intervals.
local pa_tbl = {}
local pa_lim = 8000000
local pa_i = 0
while pa_i < pa_lim do
    pa_tbl[pa_i] = pa_i + 1
    pa_i = pa_i + 2
end
local pa_checksum = 0
local pa_wit_i = 0
while pa_wit_i < pa_lim do
    pa_checksum = pa_checksum + (pa_wit_i + 1) * pa_tbl[pa_wit_i]
    pa_wit_i = pa_wit_i + 2
end
print("TABLE 0 (Phase A) CHECKSUM", pa_checksum)

-- PHASE B — The Staircase
-- Shape: Nested loops where the inner bound is tied to the outer induction
-- variable (pb_outer_i). The table is populated entirely within the inner loop.
-- The required capacity scales dynamically per outer iteration, validating
-- idempotency of capacity hoisting within region bounds.
local pb_tbl = {}
local pb_lim = 100000
local pb_outer_i = 0
while pb_outer_i < pb_lim do
    local pb_inner_i = 0
    while pb_inner_i < pb_outer_i do
        pb_tbl[pb_inner_i] = pb_inner_i + 1
        pb_inner_i = pb_inner_i + 1
    end
    pb_outer_i = pb_outer_i + 1
end
local pb_checksum = 0
local pb_wit_i = 0
-- The max inner index written is pb_lim - 2 (which is 99998)
while pb_wit_i < 99999 do
    pb_checksum = pb_checksum + (pb_wit_i + 1) * pb_tbl[pb_wit_i]
    pb_wit_i = pb_wit_i + 1
end
print("TABLE 1 (Phase B) CHECKSUM", pb_checksum)

-- PHASE C — The Polisher
-- Shape: Two consecutive, independent loops over the same table and limits.
-- The first loop performs a constant fill; the second performs a
-- read-modify-write on the same keys. Validates consecutive root analysis
-- and scalar add folding.
local pc_tbl = {}
local pc_lim = 2500000
local pc_i = 0
while pc_i < pc_lim do
    pc_tbl[pc_i] = 5
    pc_i = pc_i + 1
end
local pc_j = 0
while pc_j < pc_lim do
    pc_tbl[pc_j] = pc_tbl[pc_j] + 1
    pc_j = pc_j + 1
end
local pc_checksum = 0
local pc_wit_i = 0
while pc_wit_i < pc_lim do
    pc_checksum = pc_checksum + (pc_wit_i + 1) * pc_tbl[pc_wit_i]
    pc_wit_i = pc_wit_i + 1
end
print("TABLE 2 (Phase C) CHECKSUM", pc_checksum)

-- PHASE D — The Sentinel
-- Shape: Data-dependent termination. The search loop iterates until it
-- hits a sentinel value placed dynamically in the array. This acts as an
-- untraceable def-use cycle, forcing execution onto the dynamic path as
-- bounds cannot be statically verified ahead of the loop.
local pd_tbl = {}
local pd_fill_i = 0
while pd_fill_i < 30000 do
    pd_tbl[pd_fill_i] = 1
    pd_fill_i = pd_fill_i + 1
end
pd_tbl[30] = 60
local pd_sentinel_val = 60
local pd_search_i = 0
while pd_tbl[pd_search_i] < pd_sentinel_val do
    pd_search_i = pd_search_i + 1
end
local pd_diary = {}
pd_diary[0] = pd_search_i

local pd_checksum1 = 0
local pd_wit_i1 = 0
while pd_wit_i1 < 30000 do
    pd_checksum1 = pd_checksum1 + (pd_wit_i1 + 1) * pd_tbl[pd_wit_i1]
    pd_wit_i1 = pd_wit_i1 + 1
end
pd_checksum1 = pd_checksum1 + (30 + 1) * pd_tbl[30] -- Account for the sentinel
print("TABLE 3 (Phase D) CHECKSUM", pd_checksum1)
print("TABLE 4 (Phase D) DIARY[0]", pd_diary[0])

-- PHASE E — The Frozen Handoff
-- Shape: The outer induction variable is captured as a loop-invariant
-- value for the inner loop. The inner loop writes repeatedly to the same
-- frozen index, demonstrating boundary subsumption where the outer bound
-- safely acts as the key constraint.
local pe_tbl = {}
local pe_outer_lim = 2000000
local pe_inner_lim = 3
local pe_outer_i = 0
while pe_outer_i < pe_outer_lim do
    local pe_frozen_i = pe_outer_i
    local pe_inner_i = 0
    while pe_inner_i < pe_inner_lim do
        pe_tbl[pe_frozen_i] = 7
        pe_inner_i = pe_inner_i + 1
    end
    pe_outer_i = pe_outer_i + 1
end
local pe_checksum = 0
local pe_wit_i = 0
while pe_wit_i < pe_outer_lim do
    pe_checksum = pe_checksum + (pe_wit_i + 1) * pe_tbl[pe_wit_i]
    pe_wit_i = pe_wit_i + 1
end
print("TABLE 5 (Phase E) CHECKSUM", pe_checksum)

-- PHASE F — The Carried Alias
-- Shape: Identical nesting to Phase E, but the inner loop IV is initialized
-- by the outer loop IV, creating a shifting offset. Sequential contiguous
-- writes occur across dynamically shifting windows.
local pf_tbl = {}
local pf_lim = 60000
local pf_outer_i = 0
while pf_outer_i < pf_lim do
    local pf_inner_i = pf_outer_i
    while pf_inner_i < pf_lim do
        pf_tbl[pf_inner_i] = pf_inner_i + 1
        pf_inner_i = pf_inner_i + 1
    end
    pf_outer_i = pf_outer_i + 1
end
local pf_checksum = 0
local pf_wit_i = 0
while pf_wit_i < pf_lim do
    pf_checksum = pf_checksum + (pf_wit_i + 1) * pf_tbl[pf_wit_i]
    pf_wit_i = pf_wit_i + 1
end
print("TABLE 6 (Phase F) CHECKSUM", pf_checksum)

-- PHASE G — The Mirror
-- Shape: Sequential reads from a source table paired with non-constant
-- arithmetic (limit - 1 - index) writes. This reverses the array order
-- dynamically and prevents constant-offset tracing on the destination.
local pg_src_tbl = {}
local pg_dst_tbl = {}
local pg_lim = 180
local pg_i = 0
while pg_i < pg_lim do
    pg_src_tbl[pg_i] = pg_i + 1
    pg_i = pg_i + 1
end
local pg_j = 0
while pg_j < pg_lim do
    local pg_rev_j = pg_lim - 1 - pg_j
    pg_dst_tbl[pg_rev_j] = pg_src_tbl[pg_j]
    pg_j = pg_j + 1
end
local pg_checksum1 = 0
local pg_wit_i1 = 0
while pg_wit_i1 < pg_lim do
    pg_checksum1 = pg_checksum1 + (pg_wit_i1 + 1) * pg_src_tbl[pg_wit_i1]
    pg_wit_i1 = pg_wit_i1 + 1
end
print("TABLE 7 (Phase G) SRC CHECKSUM", pg_checksum1)

local pg_checksum2 = 0
local pg_wit_i2 = 0
while pg_wit_i2 < pg_lim do
    pg_checksum2 = pg_checksum2 + (pg_wit_i2 + 1) * pg_dst_tbl[pg_wit_i2]
    pg_wit_i2 = pg_wit_i2 + 1
end
print("TABLE 8 (Phase G) DST CHECKSUM", pg_checksum2)

-- PHASE H — The Abacus
-- Shape: Standard ramp fill followed by a loop-carried scalar reduction
-- gathering array elements into an accumulator.
local ph_tbl = {}
local ph_lim = 1000000
local ph_i = 0
while ph_i < ph_lim do
    ph_tbl[ph_i] = ph_i + 1
    ph_i = ph_i + 1
end
local ph_sum = 0
local ph_j = 0
while ph_j < ph_lim do
    ph_sum = ph_sum + ph_tbl[ph_j]
    ph_j = ph_j + 1
end
local ph_diary = {}
ph_diary[0] = ph_sum

local ph_checksum1 = 0
local ph_wit_i1 = 0
while ph_wit_i1 < ph_lim do
    ph_checksum1 = ph_checksum1 + (ph_wit_i1 + 1) * ph_tbl[ph_wit_i1]
    ph_wit_i1 = ph_wit_i1 + 1
end
print("TABLE 9 (Phase H) CHECKSUM", ph_checksum1)
print("TABLE 10 (Phase H) DIARY[0]", ph_diary[0])

-- PHASE I — The One-Shot
-- Shape: A loop gated purely by a boolean flag rather than an induction
-- limit. The flag is cleared inside the body, guaranteeing single execution
-- and preventing static capacity induction altogether.
local pi_tbl = {}
local pi_cond = 0 < 1
local pi_i = 0
while pi_cond do
    pi_tbl[pi_i] = 100
    pi_cond = 0 < 0
    pi_i = pi_i + 1
end
local pi_checksum = 0
local pi_wit_i = 0
while pi_wit_i < 1 do
    pi_checksum = pi_checksum + (pi_wit_i + 1) * pi_tbl[pi_wit_i]
    pi_wit_i = pi_wit_i + 1
end
print("TABLE 11 (Phase I) CHECKSUM", pi_checksum)

-- PHASE J — The Terraces
-- Shape: Non-zero start index for the first loop leaves an unwritten prefix.
-- The second loop extends bounds further, forcing reallocation/capacity
-- checks to correctly span the upper bounds without overwriting the prefix zeros.
local pj_tbl = {}
local pj_lim1 = 200
local pj_i1 = 100
while pj_i1 < pj_lim1 do
    pj_tbl[pj_i1] = pj_i1 - 100
    pj_i1 = pj_i1 + 1
end
local pj_lim2 = 350
local pj_i2 = 200
while pj_i2 < pj_lim2 do
    pj_tbl[pj_i2] = pj_i2
    pj_i2 = pj_i2 + 1
end
local pj_diary = {}
pj_diary[0] = pj_tbl[150]
pj_diary[1] = pj_tbl[250]
pj_diary[2] = pj_tbl[349]
pj_diary[3] = pj_tbl[99]

local pj_checksum1 = 0
local pj_wit_i1 = 100 -- Begin exactly where the writes began to avoid unwritten 0-99
while pj_wit_i1 < pj_lim2 do
    pj_checksum1 = pj_checksum1 + (pj_wit_i1 + 1) * pj_tbl[pj_wit_i1]
    pj_wit_i1 = pj_wit_i1 + 1
end
print("TABLE 12 (Phase J) CHECKSUM", pj_checksum1)
-- In standard Lua, diary[3] will print 'nil'. In your subset, it prints '0'.
print("TABLE 13 (Phase J) DIARY", pj_diary[0], pj_diary[1], pj_diary[2], pj_diary[3])

-- PHASE K — The Cube
-- Shape: O(N^3) triple loop. The innermost write uses the innermost IV
-- as key, and combines inner and middle IVs for the payload, rigorously
-- testing bounds tracking and invariant hoisting at maximum depth.
local pk_tbl = {}
local pk_lim = 2000
local pk_i = 0
while pk_i < pk_lim do
    local pk_j = 0
    while pk_j < pk_lim do
        local pk_k = 0
        while pk_k < pk_lim do
            pk_tbl[pk_k] = pk_k + pk_j
            pk_k = pk_k + 1
        end
        pk_j = pk_j + 1
    end
    pk_i = pk_i + 1
end
local pk_checksum = 0
local pk_wit_i = 0
while pk_wit_i < pk_lim do
    pk_checksum = pk_checksum + (pk_wit_i + 1) * pk_tbl[pk_wit_i]
    pk_wit_i = pk_wit_i + 1
end
print("TABLE 14 (Phase K) CHECKSUM", pk_checksum)

-- PHASE L — The Poisoned Chalice
-- Shape: Three distinct local variables trace identically back to the
-- main induction variable. The "+ 0" verifies offset equality folding.
-- Tests if consecutive writes to analytically identical indices successfully collapse.
local pl_tbl = {}
local pl_lim = 8000
local pl_i = 0
while pl_i < pl_lim do
    local pl_key1 = pl_i
    pl_tbl[pl_key1] = 1
    local pl_key2 = pl_key1
    pl_key2 = pl_key2 + 0
    pl_tbl[pl_key2] = 2
    local pl_key3 = pl_i
    pl_tbl[pl_key3] = 3
    pl_i = pl_i + 1
end
local pl_checksum = 0
local pl_wit_i = 0
while pl_wit_i < pl_lim do
    pl_checksum = pl_checksum + (pl_wit_i + 1) * pl_tbl[pl_wit_i]
    pl_wit_i = pl_wit_i + 1
end
print("TABLE 15 (Phase L) CHECKSUM", pl_checksum)

-- PHASE M — The Handoff
-- Shape: Two table registers referencing a single allocation.
-- Sequential writes through both aliases test whether modifications
-- are cleanly resolved against the underlying shared memory root.
local pm_tbl1 = {}
local pm_tbl2 = pm_tbl1
local pm_lim = 2000000
local pm_i = 0
while pm_i < pm_lim do
    pm_tbl1[pm_i] = pm_i + 1
    pm_tbl2[pm_i] = pm_i + 2
    pm_i = pm_i + 1
end
local pm_checksum = 0
local pm_wit_i = 0
while pm_wit_i < pm_lim do
    pm_checksum = pm_checksum + (pm_wit_i + 1) * pm_tbl1[pm_wit_i]
    pm_wit_i = pm_wit_i + 1
end
print("TABLE 16 (Phase M) CHECKSUM", pm_checksum)

-- PHASE N — The Mailbox (chess move validation)
-- Shape: one long-lived board co-held by a read alias on every move,
-- plus a per-move attack table born, filled by a converted loop, folded
-- into a checksum, and explicitly dropped at move rate. For the future
-- layout classifier this phase is the canonical split: the board's site
-- is co-held (shared → header forever, growth invisible to the alias),
-- the attack site is sole (flat candidate, malloc world — 512 B stays
-- far below graduation). For the runtime it is ctor/free churn at move
-- rate, which must never touch a syscall. The wrap counters replace
-- modulo (out of subset): they advance by coprime strides and subtract
-- their period, hitting board and attack cells pseudo-randomly.
local pn_board = {}
local pn_sq = 0
while pn_sq < 4096 do
    pn_board[pn_sq] = pn_sq * pn_sq - pn_sq   -- pseudo-occupancy
    pn_sq = pn_sq + 1
end
local pn_moves = 400000
local pn_move = 0
local pn_fold = 0
local pn_w1 = 0
local pn_w2 = 0
local pn_wa = 0
while pn_move < pn_moves do
    local pn_view = pn_board                    -- read alias, every move
    local pn_attacks = {}                       -- per-move temp
    local pn_from = 0
    while pn_from < 64 do
        pn_attacks[pn_from] = pn_from + pn_move -- converted fill
        pn_from = pn_from + 1
    end
    pn_w1 = pn_w1 + 17
    while 4095 < pn_w1 do pn_w1 = pn_w1 - 4096 end
    pn_w2 = pn_w2 + 41
    while 4095 < pn_w2 do pn_w2 = pn_w2 - 4096 end
    pn_wa = pn_wa + 7
    while 63 < pn_wa do pn_wa = pn_wa - 64 end
    -- pseudo validation: fold two board cells (through the alias) and
    -- one attack cell into the accumulator
    pn_fold = pn_fold + pn_view[pn_w1] + pn_view[pn_w2] + pn_attacks[pn_wa]
    pn_attacks = nil                            -- sole → real free, every move
    pn_move = pn_move + 1
end
print("TABLE 17 (Phase N) FOLD", pn_fold)

-- PHASE O — Interleaved Ladders
-- Shape: two buffers growing in lockstep, alternately, past the
-- graduation threshold — the shape where in-place realloc luck runs
-- out (each table's neighbor is the other's expansion room; game
-- engines live here: world state + particle pool growing together).
-- The store keys are deliberately DERIVED (i + i, not the guard phi),
-- so the fill-loop conversion declines (Phase E/L behavior) and every
-- growth rides the cold arm — which is the point: this phase measures
-- the growth machinery, not the fast path. VM world: one 1 MiB
-- graduation copy each, then page commits only. Malloc world:
-- interleaved realloc/mremap per doubling. Only even cells are
-- written; the witness strides 2 like Phase A so the odd growth-zero
-- cells stay out of the arithmetic (nil≡0 delta, Phase J's note).
local po_a = {}
local po_b = {}
local po_lim = 4000000
local po_i = 0
while po_i < po_lim do
    local po_k = po_i + po_i                    -- not the phi → checked path
    po_a[po_k] = po_i
    po_b[po_k] = po_i + 1
    po_i = po_i + 1
end
local po_checksum = 0
local po_wit = 0
while po_wit < po_lim do
    po_checksum = po_checksum + (po_wit + 1) * (po_a[po_wit] + po_b[po_wit])
    po_wit = po_wit + 2
end
print("TABLE 18 (Phase O) CHECKSUM", po_checksum)

-- PHASE Q — The Far Store (sparse graduation)
-- Shape: born-empty table, one distant store, no ramp — the sparse
-- jump sizes the span to the index exactly (no overshoot). Under the
-- VM world this graduates straight from null: one PROT_NONE
-- reservation (~2 GiB), one commit, zero memcpy, zero memset — the
-- untouched gigabytes between stay uncommitted pages (resident: the
-- handful of touched pages; see the VmHWM probe in the session notes).
-- The witness prints only the written cell: the unwritten in-span
-- cells are the documented growth-zero delta and stay out of the
-- differential, exactly like Phase J's diary[3].
local pq_far = {}
pq_far[262143999] = 123456789
print("TABLE 19 (Phase Q) FAR CELL", pq_far[262143999])

-- PHASE R — The Scanline (software renderer churn)
-- Shape: per-triangle temporary born, filled by a converted loop,
-- reduced, and explicitly dropped at triangle rate. Small buffers
-- (1 KiB) that must stay in the malloc world — graduation may never
-- tax the small-table common case with a syscall; the phase pins the
-- boundary from below. In Lua this is GC pressure; in glm it is real
-- frees (sole drops) at 400 kHz.
local pr_tris = 400000
local pr_tri = 0
local pr_checksum = 0
while pr_tri < pr_tris do
    local pr_span = {}
    local pr_x = 0
    while pr_x < 128 do
        pr_span[pr_x] = pr_x * 3 + pr_tri       -- pseudo shader
        pr_x = pr_x + 1
    end
    local pr_acc = 0
    local pr_j = 0
    while pr_j < 128 do
        pr_acc = pr_acc + pr_span[pr_j]
        pr_j = pr_j + 1
    end
    pr_checksum = pr_checksum + pr_acc
    pr_span = nil                               -- sole → freed every triangle
    pr_tri = pr_tri + 1
end
print("TABLE 20 (Phase R) CHECKSUM", pr_checksum)

-- PHASE U — The Relayout (UI, WoW-addon shape)
-- Shape: per-frame layout tree — a small table built, aliased by a
-- 'child' view, written through both names (the shared-buffer race of
-- Phase M at churn rate), reduced, then dropped in sequence: child
-- first (an unhook — the buffer survives with the parent), parent
-- second (sole again → a real free). For the layout classifier this is
-- the canonical co-held site: shared → header, regardless of what the
-- drops later prove (layout is 'ever-co-held', freeing is 'sole now' —
-- independent verdicts from the same may-point-to sets).
local pu_frames = 200000
local pu_f = 0
local pu_checksum = 0
while pu_f < pu_frames do
    local pu_parent = {}
    local pu_i = 0
    while pu_i < 16 do
        pu_parent[pu_i] = pu_i
        pu_i = pu_i + 1
    end
    local pu_child = pu_parent                  -- alias: site now co-held
    pu_child[3] = pu_child[3] + pu_f
    pu_parent[7] = pu_parent[7] + pu_f
    local pu_acc = 0
    pu_i = 0
    while pu_i < 16 do
        pu_acc = pu_acc + pu_parent[pu_i]
        pu_i = pu_i + 1
    end
    pu_checksum = pu_checksum + pu_acc
    pu_child = nil                              -- unhook (parent holds it)
    pu_parent = nil                             -- sole again → real free
    pu_f = pu_f + 1
end
print("TABLE 21 (Phase U) CHECKSUM", pu_checksum)

-- PHASE Z — The Z-Axis (z-buffer / large-world array)
-- Shape: one giant sole fill (2^28 cells = 1 GiB span) then a full
-- witness pass — the graduation showcase at conversion speed: the
-- pre-header reserve graduates the table straight from null into a
-- 1 GiB reservation (one mmap, one commit — no malloc phase at all),
-- and the fill itself never leaves the fast path while pages fault in
-- lazily behind the store stream. The witness doubles as a streaming
-- read bandwidth measurement over the committed span.
-- TABLE OVERFLOW FOR LUAJIT
-- local pz_buf = {}
-- local pz_lim = 268435456                        -- 2^28 cells = 1 GiB
-- local pz_i = 0
-- while pz_i < pz_lim do
    -- pz_buf[pz_i] = pz_i + 1
    -- pz_i = pz_i + 1
-- end
-- local pz_checksum = 0
-- local pz_w = 0
-- while pz_w < pz_lim do
    -- pz_checksum = pz_checksum + pz_w * pz_buf[pz_w]
    -- pz_w = pz_w + 1
-- end
-- print("TABLE 22 (Phase Z) CHECKSUM", pz_checksum)
