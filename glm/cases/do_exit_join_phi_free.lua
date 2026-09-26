-- glm/cases/do_exit_join_phi_free.lua
-- EXPECT: 0

-- The conditional-ctor face of the do-exit family: the dying binding
-- (`x`, a bare local) carries ONE site whose constructor lives inside
-- the if-arm, so no birth register dominates the block exit. The free
-- goes through the carrier's JOIN REGISTER (DO_EXIT_FREE_PHI): at
-- runtime it holds the arm's header when the branch ran, null when it
-- did not — both operands are free-safe. The branch is taken here, so
-- the one allocation is composted and sys_alloc_count() reads 0.
--
-- This shape was invalid IR before the phi-type fix (the join phi was
-- typed i64 over ptr inputs and clang rejected the module); the phi
-- now carries the arms' joined type, ptr here.
do
  local x
  if 1 < 2 then
    local w = {}
    w[0] = 7
    x = w
  end
end
print(sys_alloc_count())
