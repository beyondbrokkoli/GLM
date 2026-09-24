-- EXPECT_BUILD_FAIL: heterogeneous tables are not supported
-- An empty table literal cannot second-touch a record-typed table
-- site: join_ty(Record, Tbl(Pending)) is a Conflict.
local m = {}
m[0] = { x: 1, name: "a" }
m[1] = {}
