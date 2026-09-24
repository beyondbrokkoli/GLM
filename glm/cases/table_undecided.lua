-- EXPECT_BUILD_FAIL: a table is read before it is ever given a value
local t = {}
print(t[0])
