-- EXPECT: 1
-- BASELINE: wrong per the value-semantics claim, correct per the
-- current lowering. Records are heap GlmTables: constructing one
-- moves sys_alloc_count() — the value-semantics claim ("record
-- drops must not move the counter") is FALSE at baseline because
-- records allocate and cannot be dropped at all (see BS-1).
local r = { x: 100, y: 200 }
print(sys_alloc_count())
