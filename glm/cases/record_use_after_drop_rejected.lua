-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
-- Use-after-drop, kept standalone: a name dropped by t = nil is
-- poisoned for the rest of its scope — table reads, stores, and '#'
-- through a possibly-nil name are rejected at compile time. A drop
-- under an if poisons the name too (the scope merge carries the null
-- possibility). Semantics documented in docs/records_and_memory.md
-- A.1.
local t = {}
t[0] = 7
t = nil
print(t[0])
