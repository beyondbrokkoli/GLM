-- EXPECT: 1	2
-- BASELINE: wrong-but-current. Duplicate keys are silently accepted
-- and become two positional slots (slot 0 = 1, slot 1 = 2). Lua
-- semantics would be last-wins with a single field.
local a = { x: 1, x: 2 }
print(a[0], a[1])
