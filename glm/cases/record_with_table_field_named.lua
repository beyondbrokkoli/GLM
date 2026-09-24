-- EXPECT: 42
-- BASELINE: current behavior, restricted. An identifier-held table
-- field keeps the record's Record type (no child site), so the
-- record itself leaks at block exit and only field 0 is printable:
-- the checker types EVERY record index as field 0's type
-- (type_checker.rs:206-213); r[1] ("nested", a Str) is
-- checker-typed Table(Int) and rejected by the print gate —
-- see record_nonfirst_field_print_rejected.lua.
local inner_tbl = { 42 }
local r = { data: inner_tbl, label: "nested" }
print(r[0][0])
