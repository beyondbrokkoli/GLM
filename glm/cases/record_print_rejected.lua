-- EXPECT_BUILD_FAIL: records compile as tables, cannot be printed directly
-- BS-6: print(r) passes the checker (the print gate rejects Table(_)
-- only) and panics the backend's unreachable Record arm
-- (backend.rs:520). A compiler panic, pinned as a build failure.
local r = { x: 1, name: "a" }
print(r)
