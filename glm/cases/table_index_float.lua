-- EXPECT_BUILD_FAIL: table index must be an Integer, got Float
local t = {}
t[1.5] = 1
