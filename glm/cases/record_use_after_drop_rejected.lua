-- glm/cases/record_use_after_drop_rejected.lua
-- (former) reads through a nil-dropped record name rejected at compile time.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the drop poisoning returns with the redesign.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local r = { x: 1, name: "a" }
r = nil
print(r[0])
end
