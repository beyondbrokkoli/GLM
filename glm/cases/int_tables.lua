-- EXPECT: 0
-- EXPECT: 8	41	42
-- EXPECT: 16	0	7
-- EXPECT: 32	99	41
-- EXPECT: 9900
-- EXPECT: 5	8
-- EXPECT: 3	8
-- Pillar 5: int tables — pure arrays. '{}' is the empty int table; a
-- store past the span grows it (doubling watermark, zero-filled) and
-- '#t' reports that span; reads inside the span of never-written cells
-- are the growth zeros; 'u = t' aliases (one buffer, growth visible
-- through both); 't = nil' drops the reference — a real free when it
-- is the last one, an unhook otherwise.

local t = {}
print(#t)
t[0] = 41
t[1] = t[0] + 1
print(#t, t[0], t[1])

-- a distant store sizes the span up front; the gap reads zero
t[10] = 7
print(#t, t[5], t[10])

-- aliasing: growth through one name is visible through the other
local u = t
u[20] = 99
print(#t, t[20], u[0])

-- ramp fill + reduce
local n = 100
local i = 0
while i < n do
    t[i] = i * 2
    i = i + 1
end
local sum = 0
i = 0
while i < n do
    sum = sum + t[i]
    i = i + 1
end
print(sum)

-- drop the reference (u still holds the buffer, so this unhooks —
-- no free fires) and reuse the name
t = nil
local w = {}
w[0] = 5
print(w[0], #w)

-- table values flow through phis like any single-word value
local pick = {}
if 1 > 2 then
    pick = {}
else
    pick = w
end
pick[1] = 3
print(w[1], #w)
