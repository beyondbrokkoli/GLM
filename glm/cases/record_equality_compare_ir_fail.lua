-- EXPECT_BUILD_FAIL: defined with type 'ptr' but expected 'i64'
-- record == record, kept standalone: the comparison passes the type
-- checker (types_compatible handles Records) but the backend compares
-- the record registers as i64 while they hold ptr values — clang
-- rejects the IR. The store path has record-aware coercion; the
-- compare path has none — see docs/records_and_memory.md C.4.
local a = { x: 1, name: "a" }
local b = { x: 2, name: "b" }
print(a == b)
