-- EXPECT_BUILD_FAIL: cannot print a table
-- First-field typing (BS-2 family): the checker types r[1] with
-- field 0's type (Table(Int)) instead of label's Str, so the
-- non-first field is unprintable through any path. The lowerer
-- would have typed it correctly — checker/lowerer desync.
local inner_tbl = { 42 }
local r = { data: inner_tbl, label: "nested" }
print(r[1])
