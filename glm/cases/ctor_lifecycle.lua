-- ctor_lifecycle.lua — a populated constructor is one heap site with a
-- birth register, exactly like '{}': do-exit frees through the birth
-- register, inline child ctors deep-free with the parent (bit 7), and
-- 't = nil' composts eagerly. sys_alloc_count pins each.
-- EXPECT: 0
-- EXPECT: 0
-- EXPECT: 20
-- EXPECT: 0
-- EXPECT: 0
do
  local t = {1, 2}
end
print(sys_alloc_count())
do
  local t = { {1}, {2} }
end
print(sys_alloc_count())
do
  local t = {[0] = {10, 20}, [1] = {30, 40}}
  print(t[0][1])
end
print(sys_alloc_count())
do
  local t = {1}
  t = nil
end
print(sys_alloc_count())
-- NOTE: a NAMED row stored into a surviving table and then read after
-- its block exits is a dangling cell (stores create no ownership edge —
-- the BS-11 family gap); it is deliberately not pinned positive here.
-- ctor_nested covers the named row with its read inside the block.
