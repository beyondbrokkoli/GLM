-- EXPECT: true
-- EXPECT: false
-- EXPECT: true
-- Table equality is pointer identity, exactly Lua's by-reference
-- comparison: two names over one buffer compare true, two distinct
-- buffers compare false.

local a = {}
local b = a
print(a == b)
print(a == {})
b[0] = 1
print(a == b)
