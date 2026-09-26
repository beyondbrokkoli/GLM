-- glm/cases/record_equality_compare_ir_fail.lua
-- (former panic) record == record passed the checker and died at clang comparing ptr registers as i64 (C.4).
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the comparison face returns with the redesign; the ctor rejection fires first today.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
local a = { x: 1, name: "a" }
local b = { x: 1, name: "b" }
print(a == b)
