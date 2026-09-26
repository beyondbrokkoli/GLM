-- glm/cases/record_print_rejected.lua
-- (former, BS-6) records passed the checker print gate and were rejected at build.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the whole-value printing returns with the redesign.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local r = { x: 1, name: "a" }
print(r)
end
