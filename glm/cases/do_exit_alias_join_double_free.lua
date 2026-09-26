-- glm/cases/do_exit_alias_join_double_free.lua
-- EXPECT: 0

-- FIXED residual of the do-exit ownership refactor — sibling pin of
-- do_exit_alias_double_free_crash, which covers the direct-rebind
-- shape (`local b = c`, one register, site dedup sees both names).
-- Here the block-local table name is an IF-JOIN whose inputs are a
-- fresh `{}` constructor and another table: the do-exit proof used to
-- count the join inputs as separate sites while the lowerer freed one
-- name per site — the same join phi register was handed to
-- glm_tbl_free twice, and the second free read the freed header's
-- garbage len (the allocator aborted; the stderr face varied — see
-- HANDOFF.md).
--
-- The emission is per SITE through its TableNew BIRTH REGISTER now
-- (DO_EXIT_FREE_DEFREG): the header never moves (alias invariant), so
-- w's register and pick's fresh-ctor register hold exactly the two
-- headers on every path — each freed once, the join phi untouched.
-- sys_alloc_count() reads 0: no double free (the old abort), no leak.
--
-- The same shape at TOP LEVEL never fires the do-exit path (top-level
-- chunks emit no scope-exit frees), which is why int_tables.lua and
-- first_touch.lua carry this join legally — and why the positive
-- combos keep every case do-isolated (this file IS the do-wrapped
-- copy, green now).
do
  local w = {}
  w[0] = 5
  local pick = {}
  if 1 > 2 then
    pick = w
  end
end
print(sys_alloc_count())
