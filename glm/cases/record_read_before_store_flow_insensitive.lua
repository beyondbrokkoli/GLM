-- EXPECT: 0
-- EXPECT: 5
-- BASELINE: current behavior, documented. Typing is flow-insensitive:
-- a read textually before the only store still acquires the store's
-- element type and compiles; the early read sees the zeroed slot.
-- (With no store anywhere, table_undecided.lua's panic fires.)
local m = {}
print(m[0])
m[0] = 5
print(m[0])
