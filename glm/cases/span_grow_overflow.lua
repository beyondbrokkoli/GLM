-- glm/cases/span_grow_overflow.lua
-- SAFE: the C-ABI sparse bridge routes the huge index into the HashMap
-- backing store, so no dangerous GEP is ever computed.  The program
-- completes successfully with the stored value and correct length.
--
-- EXPECT: 42
-- EXPECT: 1000
--
-- The compiler emits a checked TableSet for this dynamic index.
-- The guard fires in glm_tbl_grow (at the C-ABI boundary), not in
-- span_grow (the runtime internal), because that's where
-- wrapping_add(1) would produce i64::MIN.

local t = {}
local i = 0
while i < 1000 do
    t[i] = i
    i = i + 1
end
-- Dynamic i64::MAX to make the index opaque to LLVM
local idx = 1
local j = 0
while j < 63 do
    idx = idx * 2
    j = j + 1
end
idx = idx - 1
t[idx] = 42
print(t[idx])
print(#t)
