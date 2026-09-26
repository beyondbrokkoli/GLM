-- glm/cases/record_basics.lua
-- combo (former): record construction and positional access — canonical slot order, first-field-typed writes, mixed field round-trips.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the k: v spelling must not silently re-accept.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local r = { x: 1, name: "a" }
print(r[0], r[1])
end
