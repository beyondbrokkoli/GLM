-- break_span_grow_overflow.lua
-- SAFE: the C-ABI sparse bridge routes the huge index into the HashMap
-- backing store, so no dangerous GEP is ever computed.  The program
-- completes successfully.
--
-- EXPECT: 40
-- EXPECT: 1000

local t = {}
local i = 0
while i < 1000 do
    t[i] = i
    i = i + 1
end

-- Dynamically compute i64::MAX to make the index opaque to LLVM
local idx = 1
local j = 0
while j < 63 do
    idx = idx * 2
    j = j + 1
end
idx = idx - 1

t[idx] = 40
print(t[idx])
print(#t)
