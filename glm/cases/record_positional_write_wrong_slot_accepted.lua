-- EXPECT: 10
-- BASELINE: wrong-but-current. p[1] = 5 stores an Int into the
-- name:Str slot: check_index_base checks EVERY record index against
-- field 0's type only (type_checker.rs:206-213). Reading the slot
-- back as a string inttoptrs 5 into a pointer and segfaults —
-- reproducer in docs/records-and-memory.md BS-5.
local p = { x: 10, name: "init" }
p[1] = 5
print(p[0])
