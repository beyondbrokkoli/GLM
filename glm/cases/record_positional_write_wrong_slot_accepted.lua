-- glm/cases/record_positional_write_wrong_slot_accepted.lua
-- (former BS-5 bug pin) a String write into the x:Int slot compiled and stored a pointer into an i64 slot.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the the unsound direction must not come back unguarded with the redesign.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local p = { x: 10, name: "init" }
p[1] = "s"
print(p[1])
end
