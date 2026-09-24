-- EXPECT_BUILD_FAIL: heterogeneous tables are not supported
-- Int vs Flt on the same key name is a shape Conflict: the Int/Flt
-- distinction propagates through record shapes and rejects the join.
local a = { x: 1, name: "alpha" }
local b = { x: 1.5, name: "beta" }
local m = {}
m[0] = a
m[1] = b
