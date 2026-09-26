-- glm/cases/record_in_table_first_touch_leak.lua
-- (former leak pin, BS-11) a record stored into a table never freed — no ownership edge for stored values.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the stored-value ownership returns with the redesign; the ctor rejection fires first today.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local m = {}
m[0] = { x: 1, name: "a" }
end
print(sys_alloc_count())
