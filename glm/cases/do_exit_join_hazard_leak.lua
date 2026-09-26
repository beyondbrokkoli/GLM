-- glm/cases/do_exit_join_hazard_leak.lua
-- EXPECT: 4
-- EXPECT: 1

-- The join-hazard face of the do-exit family: pick's binding after
-- the if carries TWO sites — its own straight-line ctor (freed
-- soundly through its birth register) and the arm-local ctor aliased
-- in the taken branch. The arm site's only sound register is pick's
-- join phi, and that phi MAY hold the already-freed straight-line
-- header on the untaken path — freeing it would double-free, so the
-- emission refuses and the arm's header leaks on the taken path
-- (DO_EXIT_JOIN_LEAK on the plate; the runtime sidecar's leak slot
-- fires too). A bounded, loud leak is the conservative outcome, the
-- same trade `t = nil` makes when the alias union is unprovable.
--
-- The read between the join and the exit is exactly why the free
-- cannot move earlier (arm-end frees would leave the read dangling):
-- pick[0] prints 4, the taken branch's value, and sys_alloc_count()
-- reads 1 — the leaked header. The untaken path (change 1 < 2 to
-- 2 < 1) leaks nothing: the arm ctor never ran.
do
  local pick = {}
  pick[0] = 3
  if 1 < 2 then
    local w = {}
    w[0] = 4
    pick = w
  end
  print(pick[0])
end
print(sys_alloc_count())
