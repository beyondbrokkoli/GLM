-- EXPECT: 0
-- EXPECT: 0
-- FIXED by the lifecycle-parity strike (was 1 / 1, BS-1 Record
-- Immortality): the do-block exit free now covers Record locals, so
-- both blocks net zero. A record and a table have identical
-- block-scope lifecycles.
do
  local r = { x: 1, name: "a" }
end
print(sys_alloc_count())
do
  local t = {}
  t[0] = 1
end
print(sys_alloc_count())
