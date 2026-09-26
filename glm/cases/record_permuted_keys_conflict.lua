-- glm/cases/record_permuted_keys_conflict.lua
-- (former) permuted field order joined cleanly — fields sorted at parse.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the field canonicalization returns with the redesign.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
local a = { name: "alpha", x: 1 }
local b = { x: 2, name: "beta" }
print(a[0], b[0])
