-- EXPECT: 1
-- EXPECT: leaked
-- `local x` without initializer: the shape layer always modeled it as a
-- nil-valued binding (Pending, NULL_ROOT alias), but the type checker
-- and the lowerer zipped names against initializer exprs, so the name
-- was never declared there and the first use died as "Undeclared
-- variable". Fixed in both layers: bare locals declare over a null
-- register with a private Unknown type variable (ids count down from
-- usize::MAX), the first assignment unifies with anything, and a nil
-- release on the still-unbound name is a no-op. The alias-union drop
-- still refuses to free ('a' holds the same site) — leak by design.
local a = {}
a[0] = 1
local target
target = a
target = nil
print(sys_alloc_count())
print("leaked")
