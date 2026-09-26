-- EXPECT: 1
-- BASELINE: wrong-but-current and nondeterministic. m[0] is a null
-- child row (nested first-touch types m as Table(Table(Int)) but
-- never allocates the row): the store is a silent no-op
-- (rt.rs:134-136). The companion read print(m[0][0]) is NOT pinnable:
-- glm_tbl_get early-returns on a null table WITHOUT zero-filling the
-- destination (rt.rs:201-203), so it reads uninitialized stack —
-- 0 in one process, 140721637957568 in another. Reproducer and
-- analysis: the BS-9 blind spot (archived notes). Only the allocation
-- count is stable here: exactly one table (m) was allocated.
local m = {}
m[0][0] = 5
print(sys_alloc_count())
