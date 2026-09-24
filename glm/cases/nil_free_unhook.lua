-- EXPECT: 7
-- EXPECT: 9	8
-- 'x = nil' drops that one reference (the freeing discipline: see src/lowerer.rs and src/rt.rs docs):
-- with a live alias it is a pure unhook — no free call at all, the
-- buffer stays with its remaining referencer, exactly Lua's rebind.
-- The alias's own later drop IS the sole live reference: the one real
-- glm_tbl_free. Then the retired name is reusable for a fresh table.
local t = {}
t[0] = 7
local u = t
t = nil
print(u[0])
u = nil
t = {}
t[1] = 9
print(t[1], #t)
