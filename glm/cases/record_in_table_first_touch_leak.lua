-- EXPECT: 1
-- BASELINE: wrong-but-current, now the RESIDUAL gap after strikes
-- 1-4. The outer table m is Table-typed and frees at block exit; the
-- stored record does not: it entered via first-touch store, not an
-- inline constructor, so no ownership edge exists for the deep-free
-- flag — proving it would require new analysis (an anonymous value
-- stored into m[0] is only reachable through m, but named records
-- stored the same way are owned elsewhere). Documented in
-- docs/records-and-memory.md as the remaining ownership-model gap.
do
  local m = {}
  m[0] = { x: 1, name: "a" }
end
print(sys_alloc_count())
