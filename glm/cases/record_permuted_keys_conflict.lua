-- EXPECT_BUILD_FAIL: type conflict
-- Field order permutations are rejected by the type checker's
-- exact-equality unify (no Record merge arm, type_checker.rs:399-434)
-- even though shape's join_ty is order-insensitive by name — the
-- BS-2 desync. The strict layer wins at compile time.
local a = { x: 1, name: "alpha" }
local b = { name: "beta", x: 2 }
local m = {}
m[0] = a
m[1] = b
