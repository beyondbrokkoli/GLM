-- EXPECT_BUILD_FAIL: table index must be an Integer, got Float
local t = {}
local x = t[2.5]
