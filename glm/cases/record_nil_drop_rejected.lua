-- EXPECT: 1
-- EXPECT: 0
-- FIXED by the lifecycle-parity strike (was EXPECT_BUILD_FAIL
-- 'nil' releases tables, BS-1 Record Immortality): records are heap
-- GlmTables, so r = nil is a valid drop request — the shape layer's
-- sole-ownership proof covers records and the lowerer emits
-- TableFree; the counter returns to 0.
local r = { x: 1, name: "a" }
print(sys_alloc_count())
r = nil
print(sys_alloc_count())
