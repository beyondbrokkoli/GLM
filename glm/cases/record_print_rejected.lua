-- EXPECT_BUILD_FAIL: records compile as tables, cannot be printed directly
-- Gate 4: print(r) passes the checker (the print gate rejects Table(_)
-- only) and is rejected by the backend's ledgered error recovery —
-- a graceful build failure, no compiler panic.
local r = { x: 1, name: "a" }
print(r)
