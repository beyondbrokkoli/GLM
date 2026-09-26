-- ctor_nested.lua — tables are containers, not elements: a layer whose
-- entries are all tables is a table-typed array, and each nested table
-- is its own monomorphic layer (their element types must agree
-- recursively — ctor_nested_mixed_rejected pins the refusal). Inline
-- rows are anonymous and deep-freed with the parent; named rows keep
-- their own binding.
-- EXPECT: 1	2	3	4
-- EXPECT: string
-- EXPECT: string
-- EXPECT: 0
-- EXPECT: 5
do
local m = { {1, 2}, {3, 4} }
print(m[0][0], m[0][1], m[1][0], m[1][1])

-- first-touch through a stored row: t[0] = nested types t as a
-- table-typed array, t[0][0] = "string" then decides the nested layer
local nested = {}
local t = {}
t[0] = nested
t[0][0] = "string"
print(t[0][0])

-- the constructor spelling of the same shape
local u = { {"string"} }
print(u[0][0])

-- stores still flow through ctor-built rows (m stays Table(Table(Int)))
m[0][0] = 9
print(m[0][0] - 9)

local named = {}
do
  local row = {5, 6}
  named[0] = row
  print(named[0][0])
end
end
