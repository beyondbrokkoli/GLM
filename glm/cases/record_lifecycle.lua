-- glm/cases/record_lifecycle.lua — combo: the record lifetime story —
-- block-exit frees, deep-free of inline children, and the heap-
-- allocation counter. Each case below is a former standalone positive
-- case, isolated in its own do-block; the EXPECT pins concatenate in
-- file order. The sys_alloc_count() pins rely on do-block isolation:
-- every block below nets zero live tables by its exit, so each counter
-- print observes only its own block's sites.

-- record_block_scope_leak.lua: FIXED by the lifecycle-parity strike
-- (was 1 / 1, BS-1 Record Immortality): the do-block exit free now
-- covers Record locals, so both blocks net zero. A record and a table
-- have identical block-scope lifecycles.
-- EXPECT: 0
-- EXPECT: 0
do
do
  local r = { x: 1, name: "a" }
end
print(sys_alloc_count())
do
  local t = {}
  t[0] = 1
end
print(sys_alloc_count())
end

-- record_with_table_field_inline.lua: FIXED by the deep-free
-- preservation strike (was 1, BS-4). Shape's child_sites fast path no
-- longer strips Record-ness from records with inline table fields, so
-- the record keeps its Record type, the block-exit free covers it
-- (lifecycle strike), and the deep-free flag is computed from the real
-- field types (data is an inline TableCtor) — the child table frees
-- with the parent.
-- EXPECT: 0
do
  local b = { data: { 1, 2, 3 } }
end
print(sys_alloc_count())

-- record_with_table_field_named.lua: FIXED by the lifecycle-parity
-- strike (was 1): the record r now frees at block exit and inner_tbl
-- is freed as its own Table local, so the block nets zero. The
-- deep-free flag stays unset (data holds a named identifier, not an
-- inline constructor — ownership belongs to inner_tbl's own binding;
-- flagging it would double-free). Field access note: r[0][0] prints
-- because field 0 holds the table; non-first fields remain
-- unprintable (BS-2 family, unfixed).
-- EXPECT: 42
-- EXPECT: 0
do
  local inner_tbl = { 42 }
  local r = { data: inner_tbl, label: "nested" }
  print(r[0][0])
end
print(sys_alloc_count())

-- record_in_record_inline_ir_fail.lua: FIXED by the coercion +
-- lifecycle + deep-free strikes (was a build-fail pin: invalid LLVM IR
-- from the missing ptrtoint; then stepwise counter leaks of 2, then
-- 1). Nested record round-trip a[0][0] == 'a'; the outer record frees
-- at block exit with the deep-free flag set (inline Record field), so
-- the inner record is freed too — the counter returns to 0.
-- EXPECT: a
-- EXPECT: 0
do
  local a = { inner: { x: 1, name: "a" } }
  print(a[0][0])
end
print(sys_alloc_count())

-- record_counter_heap_allocated.lua: BASELINE: wrong per the
-- value-semantics claim, correct per the current lowering. Records are
-- heap GlmTables: constructing one moves sys_alloc_count() — the
-- value-semantics claim ("record drops must not move the counter") is
-- FALSE at baseline because records allocate and cannot be dropped at
-- all (see BS-1). The record is alive at the print, hence 1; the block
-- exit frees it, so the next case starts clean.
-- EXPECT: 1
do
  local r = { x: 100, y: 200 }
  print(sys_alloc_count())
end
