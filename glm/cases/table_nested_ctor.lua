-- EXPECT: 0
-- Nested table via constructor elements
local inner = {}
local t = {inner}
print(t[0][0])
