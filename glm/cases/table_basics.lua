-- glm/cases/table_basics.lua — combo: the flat (non-nested) table
-- story — the float/bool/string table pillars, first-touch element
-- decision, the '#t' span baseline, pointer identity. Each case below
-- is a former standalone positive case, isolated in its own do-block;
-- the EXPECT pins concatenate in file order. int_tables.lua and
-- first_touch.lua stay standalone top-level: their trailing if-join
-- over a fresh '{}' aborts under do-block isolation (pinned in
-- do_exit_alias_join_double_free.lua).

-- float_tables.lua: Pillar 6: float tables — monomorphic arrays of
-- Pillar 2. '{e1, e2}' takes its element type from the first element
-- (all must agree, no coercion); '{}' stays the empty int table. The
-- array story is the int tables' story: a store past the span grows it
-- (doubling watermark, zero-filled — a float table's zero is 0.0,
-- printed as '0'), '#t' reports the span, 'u = t' aliases, and
-- 't = nil' is the same compile-time refcounted release (an unhook
-- while 'u' lives).
-- EXPECT: 8	1.5	2.5	0
-- EXPECT: 16	0	7.25
-- EXPECT: 32	1.125	2.5
-- EXPECT: 3.5	5.5	0.5	32
-- EXPECT: 3.5
do
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
end

-- float_table_bool_elem.lua: Pillar 7: bool tables — byte-packed cells
-- (the pillars charter; bitpacking would force read-modify-write
-- stores). '{true, false}' is the typed constructor; the growth zero
-- reads 'false'.
-- EXPECT: true	false	false	8
-- EXPECT: false	true
do
local t = {true, false}
print(t[0], t[1], t[2], #t)
local i = 0
while i < 5 do
    t[i] = not t[i]
    i = i + 1
end
print(t[0], t[3])
end

-- string_tables.lua: Pillar 8: string tables — cells are C-string
-- pointers, one word like int/float cells. Unwritten cells are null
-- pointers: '#t' and stores are fine, but printing or comparing one is
-- not (that is why the fuzzer never prints unwritten string cells).
-- EXPECT: hello	world	8
-- EXPECT: world
do
local s = {}
s[0] = "hello"
s[1] = "world"
print(s[0], s[1], #s)
local u = s
print(u[1])
end

-- table_elem_float.lua: first touch decides: '{}' becomes a FloatTable
-- when the first value stored through any alias is a Float. Strict
-- typing — a later Integer store into the same table is still an error
-- (float_table_store_int).
-- EXPECT: 1.5	8	2.5
do
local t = {}
t[0] = 1.5
local u = t
u[1] = 2.5
print(t[0], #t, u[1])
end

-- table_len_capacity_floor.lua: BASELINE: wrong-but-current. #t is the
-- allocated span length with a floor of 8 (span_grow:
-- max(want, 2*len, 8), rt.rs:266), not the element count: one store to
-- m[0] makes #m == 8. An untouched table has len 0.
-- EXPECT: 8
-- EXPECT: 0
do
local m = {}
m[0] = 1
print(#m)
local n = {}
print(#n)
end

-- table_identity.lua: table equality is pointer identity, exactly
-- Lua's by-reference comparison: two names over one buffer compare
-- true, two distinct buffers compare false.
-- EXPECT: true
-- EXPECT: false
-- EXPECT: true
do
local a = {}
local b = a
print(a == b)
print(a == {})
b[0] = 1
print(a == b)
end

-- do_test.lua: do-blocks nest; a block-local table dies with its block
-- while the outer table lives on.
-- EXPECT: 1
-- EXPECT: 10
-- EXPECT: 2
do
local t = {1, 2, 3}
print(t[0])
do
  local big = {10, 20, 30, 40, 50}
  print(big[0])
end
print(t[1])
end
