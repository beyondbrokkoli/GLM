-- glm/cases/do_exit_alias_join_double_free.lua
-- EXPECT_PANIC: glm: table allocation of

-- RESIDUAL of the do-exit ownership refactor — sibling pin of
-- do_exit_alias_double_free_crash, which covers the direct-rebind
-- shape (`local b = c`, one register, site dedup sees both names).
-- Here the block-local table name is an IF-JOIN whose inputs are a
-- fresh `{}` constructor and another table: the do-exit free goes
-- through the exit-time phi register while the per-site dedup still
-- treats the join inputs as separate sites — the phi's current header
-- is handed to glm_tbl_free twice, and the second free reads the
-- freed header's garbage len.
--
-- The death is certain; its stderr face is not (allocator state
-- decides): usually 'glm: table allocation of 18446744073709551615
-- bytes failed' (negative len through elem_layout — the same face the
-- i64::MAX alloc probes showed), sometimes a garbage byte count,
-- occasionally glibc's own 'free(): invalid pointer'. The pin matches
-- the stable prefix of the common face; the stderr-matching mechanic
-- is being aligned with this variance (see HANDOFF.md).
--
-- The same shape at TOP LEVEL never fires the do-exit path (top-level
-- chunks emit no scope-exit frees), which is why int_tables.lua and
-- first_touch.lua carry this join legally — and why the positive
-- combos keep every case do-isolated (a do-wrapped copy of either
-- case aborts exactly like this one).
do
  local w = {}
  w[0] = 5
  local pick = {}
  if 1 > 2 then
    pick = w
  end
end
