-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
-- Reading through a dropped name is the old use-after-free UB — under
-- clang -O3 it printed different garbage per run (UB probe 3). It is
-- a compile error now: the null rebind never feeds a table op.
local t = {}
t[0] = 7
t = nil
local x = t[0]
print(x)
