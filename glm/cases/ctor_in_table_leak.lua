-- ctor_in_table_leak.lua
-- (BS-11 successor, pinned knowingly) an INLINE constructor stored into
-- a table cell has no ownership edge: the parent's deep-free flag is
-- computed from its own constructor's inline children (bit 7), not from
-- later stores, so the anonymous row outlives the parent's do-exit
-- free. Bounded leak, no double free — the row is unreachable, not
-- dangling. The ownership edge is the open question the next
-- constructor round inherits; do NOT "fix" this by flagging stored
-- values: a named row stored the same way is owned by its own binding
-- and flagging it double-frees (the old BS-11 trap).
-- EXPECT: 7	8
-- EXPECT: 1
do
  local m = {}
  m[0] = {7, 8}
  print(m[0][0], m[0][1])
end
print(sys_alloc_count())
