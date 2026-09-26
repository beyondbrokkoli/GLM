-- glm/cases/record_positional_write_int_rejected.lua
-- (former, BS-5 mirror) an Int write into the field-0 Str slot was rejected.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the per-field positional typing returns with the redesign.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local p = { x: 10, name: "init" }
p[1] = 5
end
