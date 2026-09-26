-- glm/cases/record_nil_drop_rejected.lua
-- (former) record nil-release parity: records are heap GlmTables, valid nil-release targets.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the nil-release parity returns with the redesign.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local r = { x: 1, name: "a" }
r = nil
end
