-- glm/cases/nil_free_stale_redrop.lua
-- EXPECT: 0

-- The killed-site face of the drop discipline: `t = nil` inside the
-- loop is a REAL free on trip 1 (sole ownership), but the loop merge
-- resurrects the site in t's alias set (the entry snapshot predates
-- the drop), so at the block exit t still LOOKS like it holds the
-- site. The do-exit refuses the re-free (DO_EXIT_FREE_DROPPED) and
-- the explicit post-loop `t = nil` refuses it too (DROP_STALE_SITE):
-- both would hand glm_tbl_free a header that is already composted.
-- Nothing leaks and nothing dies twice — sys_alloc_count() reads 0.
--
-- Before the killed-site set, the do-exit freed the site's birth
-- register directly and the program aborted in the allocator.
do
  local t = {}
  t[0] = 5
  local i = 0
  while i < 1 do
    t = nil
    i = i + 1
  end
  t = nil
end
print(sys_alloc_count())
