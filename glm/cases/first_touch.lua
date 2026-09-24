-- EXPECT: 1.5
-- EXPECT: 2.5	2.5
-- EXPECT: 7	8
-- EXPECT: 0
-- The first-touch decision flows through aliases and if-joins: every
-- name that may hold the site at the store carries the decision, and
-- a dead pre-if '{}' adopts the element of the table that replaces it.
local t = {}
local u = t
u[0] = 1.5
print(t[0])

local pick = {}
if 1 > 2 then
    pick = {}
else
    pick = t
end
pick[1] = 2.5
print(pick[1], t[1])

-- a separate site stays Integer under the same discipline
local ints = {}
local i = 0
while i < 8 do
    ints[i] = i
    i = i + 1
end
print(ints[7], #ints)

-- an empty table nobody reads through is dead, not undecided
local dead = {}
print(#dead)
