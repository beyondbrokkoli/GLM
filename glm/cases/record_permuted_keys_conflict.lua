-- EXPECT: alpha	beta
-- FIXED by the canonicalization strike (was EXPECT_BUILD_FAIL type
-- conflict, BS-2): the parser sorts fields alphabetically, so
-- permuted literals produce identical positional layouts, shape's
-- order-insensitive join and the checker's exact-equality unify now
-- agree, and both records canonicalize to [name, x].
local a = { x: 1, name: "alpha" }
local b = { name: "beta", x: 2 }
local m = {}
m[0] = a
m[1] = b
print(m[0][0], m[1][0])
