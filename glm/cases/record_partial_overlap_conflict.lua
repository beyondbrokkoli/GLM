-- EXPECT_BUILD_FAIL: heterogeneous tables are not supported
-- Partial key overlap ({x:1,name:"alpha"} vs {x:2}) is a compile
-- conflict: join_ty requires equal field counts and identical names.
local a = { x: 1, name: "alpha" }
local b = { x: 2 }
local m = {}
m[0] = a
m[1] = b
