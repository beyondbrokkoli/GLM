-- glm/cases/nested_shapes.lua — combo: nesting shapes — tables in
-- tables built every legal way (index-assigned children, aliased
-- rows, 2D spines) now that populated constructors are cut. Each case
-- below is a former standalone positive case, isolated in its own
-- do-block; the EXPECT pins concatenate in file order. The former
-- record-in-table sections moved to the constructor-rejection pins
-- (record_in_table_first_touch_leak and friends).

-- table_nested.lua: nested table via index assignment.
-- EXPECT: 0
do
local t = {}
t[0] = {}
print(t[0][0])
end

-- table_nested_alias.lua: nested table via an aliased row (the
-- constructor-cut rewrite of the old '{inner}' literal: the row is
-- its own binding, stored into the spine).
-- EXPECT: 0
do
local inner = {}
local t = {}
t[0] = inner
print(t[0][0])
end

-- nested_tables.lua: 2D matrix, store-built rows.
-- EXPECT: 1
-- EXPECT: 2
-- EXPECT: 3
-- EXPECT: 4
do
local r0 = {}
r0[0] = 1
r0[1] = 2
local r1 = {}
r1[0] = 3
r1[1] = 4
local mat = {}
mat[0] = r0
mat[1] = r1
print(mat[0][0])
print(mat[0][1])
print(mat[1][0])
print(mat[1][1])
end

-- nested_homogeneous.lua: 2D integer matrix, store-built + cell
-- mutation.
-- EXPECT: 42
-- EXPECT: 2
-- EXPECT: 3
-- EXPECT: 4
-- EXPECT: 8
do
local r0 = {}
r0[0] = 1
r0[1] = 2
local r1 = {}
r1[0] = 3
r1[1] = 4
local m = {}
m[0] = r0
m[1] = r1
m[0][0] = 42
print(m[0][0])
print(m[0][1])
print(m[1][0])
print(m[1][1])
print(#m)
end
