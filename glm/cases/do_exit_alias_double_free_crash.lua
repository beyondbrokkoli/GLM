-- EXPECT: 1
-- EXPECT: 0
-- FIXED by the do-exit ownership refactor (was a RUNTIME ABORT, exit
-- 134): `local b = c` binds b to the same register as c, and scope
-- exit used to emit TableFree for every block-local of owned heap
-- type — the one table freed twice, the second glm_tbl_free re-boxing
-- freed memory until the allocator aborted. The free decision moved
-- into shape analysis (decide_do_exit): a heap site frees at do-exit
-- iff no binding that survives the block holds it, ONE TableFree per
-- site regardless of how many dying names alias it. Here c and b both
-- die with the block, so the site frees exactly once — DO_EXIT_FREE_
-- SITE + DO_EXIT_FREE_SHARED on the plate. The surviving-alias shape
-- (block-local aliasing an outer table) is now a loud compile-time
-- rejection instead of the old silent early free (see
-- do_exit_alias_survives_rejected).
do
  local c = {}
  c[0] = 1
  local b = c
  print(sys_alloc_count())
end
print(sys_alloc_count())
