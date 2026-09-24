-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
local t = {0.5}
t[0] = 1
