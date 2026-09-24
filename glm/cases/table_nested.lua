-- EXPECT: 0
-- Nested table via index assignment
local t = {}
t[0] = {}
print(t[0][0])
