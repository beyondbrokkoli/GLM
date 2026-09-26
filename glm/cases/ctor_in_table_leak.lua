-- ctor_in_table_leak.lua
-- (BS-11, fixed) an INLINE constructor stored into a table cell now
-- rides the parent's deep-free flag: the analyzer proves the ownership
-- transfer at the store (STMT_IDX_STORED_CTOR — the value is
-- syntactically inline and the target a direct identifier store) and
-- the lowerer ORs it into TableNew bit 7, so the do-exit free of `m`
-- composts the anonymous row too. The old trap stays closed: a NAMED
-- row stored the same way (`m[0] = row`) is owned by its own binding,
-- never lands in stored_ctor_parents, and flagging it would
-- double-free — the original BS-11 trap.
-- EXPECT: 7	8
-- EXPECT: 0
do
  local m = {}
  m[0] = {7, 8}
  print(m[0][0], m[0][1])
end
print(sys_alloc_count())
