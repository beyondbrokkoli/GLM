-- glm/cases/nested_shapes.lua — combo: nesting shapes — tables in
-- tables (constructor and index-assigned) and records held in table
-- slots. Each case below is a former standalone positive case,
-- isolated in its own do-block; the EXPECT pins concatenate in file
-- order.

-- table_nested.lua: nested table via index assignment.
-- EXPECT: 0
do
local t = {}
t[0] = {}
print(t[0][0])
end

-- table_nested_ctor.lua: nested table via constructor elements.
-- EXPECT: 0
do
local inner = {}
local t = {inner}
print(t[0][0])
end

-- nested_tables.lua: 2D matrix via constructor.
-- EXPECT: 1
-- EXPECT: 2
-- EXPECT: 3
-- EXPECT: 4
do
local mat = {{1, 2}, {3, 4}}
print(mat[0][0])
print(mat[0][1])
print(mat[1][0])
print(mat[1][1])
end

-- nested_homogeneous.lua: 2D integer matrix, constructor + cell
-- mutation.
-- EXPECT: 42
-- EXPECT: 2
-- EXPECT: 3
-- EXPECT: 4
-- EXPECT: 8
do
local m = {{1, 2}, {3, 4}}
m[0][0] = 42
print(m[0][0])
print(m[0][1])
print(m[1][0])
print(m[1][1])
print(#m)
end

-- nested_conflict_assign.lua: records with matching keys but mixed
-- field types compile cleanly. Each record in the table has the same
-- shape {name: Str, x: Int} (canonicalized alphabetical slot order).
-- EXPECT: hello	1	world	2
do
local m = {}
m[0] = {x: 1, name: "hello"}
m[1] = {x: 2, name: "world"}
print(m[0][0], m[0][1], m[1][0], m[1][1])
end

-- nested_conflict_ctor.lua: canonicalized record slots: fields are
-- sorted alphabetically at parse time, so slot 0 = name, slot 1 = x
-- (pre-canonicalization golden was '0\thero').
-- EXPECT: hero	0
do
local player = { x: 0, name: "hero" }
print(player[0], player[1])
end
