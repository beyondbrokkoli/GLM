-- ctor_explicit_keys.lua — the {[k] = v} entry form (Lua 5.4 §3.4.9
-- bracketed keys, constant non-negative integers only). The positional
-- counter and explicit keys are independent (Lua's rule): {10, 20,
-- [3] = 40} writes slots 0, 1 and 3. A slot written twice is a Syntax
-- Error, not last-wins (pinned in ctor_dup_index_rejected). Keys past
-- the sparse threshold upgrade like any store.
-- EXPECT: 1	2	8
-- EXPECT: 10	20	40	8
-- EXPECT: 9
do
local b = {[0] = 1, [5] = 2}
print(b[0], b[5], #b)
local c = {10, 20, [3] = 40}
print(c[0], c[1], c[3], #c)
local sparse = {[100001] = 9}
print(sparse[100001])
end
