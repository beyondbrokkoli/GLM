-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
-- '#' is a table use like a read: through a dropped name it would load
-- from a null header, so it is rejected at compile time.
local t = {}
t = nil
print(#t)
