-- glm/cases/span_growth.lua
-- PANIC: the C-ABI guard catches i64::MAX before the GEP computes.
-- Without the guard: GEP overflows to data-8 → corrupts jemalloc
-- chunk header → realloc → SIGSEGV.
--
-- EXPECT_BUILD_FAIL: table index overflow
--
-- This test exercises a two-phase pattern:
--   1. Fill 1000 elements (fast path)
--   2. Try to grow beyond i64::MAX (panics at C-ABI boundary)
--   3. (Never reached) fill 1000 more
--
-- With the guard, phase 2 aborts cleanly before phase 3.

local t = {}
local i = 0
while i < 1000 do
    t[i] = i
    i = i + 1
end

t[9223372036854775807] = 42
i = 0
while i < 1000 do
    t[i] = i
    i = i + 1
end
print("survived")
