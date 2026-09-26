-- EXPECT_BUILD_FAIL: Lifetime Error: block-local 'b' aliases a table that outlives the block
-- Containment pin for the do-exit ownership refactor: a block-local
-- that aliases an outer-owned table used to be freed at block exit
-- anyway — an early free leaving the surviving name dangling (silent
-- use-after-free: the outer count read 0 and later table ops through
-- the name loaded freed memory). The analyzer's decide_do_exit now
-- proves, per heap site, that no surviving binding holds it; the
-- unprovable shape is rejected at compile time (DO_EXIT_ALIAS_
-- SURVIVES on the plate) until the linear-ownership redesign makes
-- real move semantics expressible. Today's loud rejection beats
-- yesterday's quiet UB.
local c = {}
c[0] = 7
do
  local b = c
end
print(sys_alloc_count())
print(c[0])
