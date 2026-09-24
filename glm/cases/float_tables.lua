-- EXPECT: 8	1.5	2.5	0
-- EXPECT: 16	0	7.25
-- EXPECT: 32	1.125	2.5
-- EXPECT: 3.5	5.5	0.5	32
-- EXPECT: 3.5
-- Pillar 6: float tables — monomorphic arrays of Pillar 2. '{e1, e2}'
-- takes its element type from the first element (all must agree, no
-- coercion); '{}' stays the empty int table. The array story is the
-- int tables' story: a store past the span grows it (doubling
-- watermark, zero-filled — a float table's zero is 0.0, printed as
-- '0'), '#t' reports the span, 'u = t' aliases, and 't = nil' is the
-- same compile-time refcounted release (an unhook while 'u' lives).
local t = {1.5, 2.5}
print(#t, t[0], t[1], t[2])

t[10] = 7.25
print(#t, t[5], t[10])

local u = t
u[20] = 1.125
print(#t, t[20], u[1])

-- converted fill (EC/HR): reserve(24) under the already-larger span,
-- check-free double stores
local i = 0
while i < 24 do
    t[i] = t[i] * 2.0 + 0.5
    i = i + 1
end
print(t[0], t[1], t[23], #t)

t = nil
print(u[0])
