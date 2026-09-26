-- glm/cases/nil_free_lifecycle.lua — combo: the 't = nil' drop
-- discipline — eager free vs unhook, conditional and repeated drops,
-- and the alias-union refusals. Each case below is a former standalone
-- positive case, isolated in its own do-block; the EXPECT pins
-- concatenate in file order. The sys_alloc_count() pins rely on
-- do-block isolation: every block above nets zero live tables by its
-- exit, so each counter print observes only its own block's sites.

-- nil_free_double.lua: a second 'x = nil' re-drops an already-dropped
-- reference: the lifetime pass sees the name bound to null only, emits
-- no free, and the old double-free segfault is a plain no-op. (Probe 1
-- of the UB series, now defined.)
-- EXPECT: survived double nil
do
local t = {}
t[0] = 41
t = nil
t = nil
print("survived double nil")
end

-- nil_free_loop.lua: a drop inside a loop is a conditional free: trip
-- 1 holds the sole live reference and frees for real; trips 2+ reach
-- the free site with the reference already dropped. The one branch
-- conditionality needs lives inside the cold glm_tbl_free (null
-- operand = no-op) — the loop body itself carries no check.
-- EXPECT: loop drop ok
do
local t = {}
t[0] = 41
local i = 0
while i < 3 do
    t = nil
    i = i + 1
end
print("loop drop ok")
end

-- nil_free_unhook.lua: 'x = nil' drops that one reference (the freeing
-- discipline: see src/lowerer.rs and src/rt.rs docs): with a live
-- alias it is a pure unhook — no free call at all, the buffer stays
-- with its remaining referencer, exactly Lua's rebind. The alias's own
-- later drop IS the sole live reference: the one real glm_tbl_free.
-- Then the retired name is reusable for a fresh table.
-- EXPECT: 7
-- EXPECT: 9	8
do
local t = {}
t[0] = 7
local u = t
t = nil
print(u[0])
u = nil
t = {}
t[1] = 9
print(t[1], #t)
end

-- nil_free_ambiguity.lua: table-typed if-phis make 'pick'
-- possibly-bound to either root, so 'pick = nil' can free neither (it
-- unhooks); both originals stay usable through their own names.
-- Conditional aliasing is legal — the ambiguity routes itself into the
-- unhook bucket.
-- EXPECT: 6	2
do
local a = {}
a[0] = 1
local b = {}
b[0] = 2
local pick = a
if 1 > 2 then
    pick = b
end
pick[0] = 5
pick = nil
a[0] = a[0] + 1
print(a[0], b[0])
end

-- bare_local_alias_bind.lua: `local x` without initializer: the shape
-- layer always modeled it as a nil-valued binding (Pending, NULL_ROOT
-- alias), but the type checker and the lowerer zipped names against
-- initializer exprs, so the name was never declared there and the
-- first use died as "Undeclared variable". Fixed in both layers: bare
-- locals declare over a null register with a private Unknown type
-- variable (ids count down from usize::MAX), the first assignment
-- unifies with anything, and a nil release on the still-unbound name
-- is a no-op. The alias-union drop still refuses to free ('a' holds
-- the same site) — leak by design (the counter reads 1 while 'a'
-- lives; the block exit itself frees the site).
-- EXPECT: 1
-- EXPECT: leaked
do
local a = {}
a[0] = 1
local target
target = a
target = nil
print(sys_alloc_count())
print("leaked")
end

-- nil_free_alias_leak.lua: alias union trap: if/else assigns different
-- tables to 'target'. After target = nil, the compiler's alias set
-- union contains both 'a' and 'b' roots, so drop_reference refuses to
-- emit TableFree for either. sys_alloc_count() reads 2 here — the two
-- tables of this block, still alive at the print (the blocks above net
-- zero, so nothing is inherited).
-- EXPECT: 2
-- EXPECT: leaked
do
local a = {}
a[0] = 1
local b = {}
b[0] = 2
local target = a
if false then
    target = b
end
target[0] = 5
target = nil
print(sys_alloc_count())
print("leaked")
end
