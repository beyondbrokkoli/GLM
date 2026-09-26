-- record_equality_compare_ir_fail.lua: former record == record clang-fail pin
--
-- RECORD SYNTAX GUARD: the {k: v} spelling was removed with the record
-- machinery (named-key constructors and mixed-type layouts are
-- not glm's model). The parse must reject it here —
-- re-acceptance of the colon form is the regression this pin catches.
-- EXPECT_BUILD_FAIL: Syntax Error: record syntax
local a = { x: 1, name: "a" }
local b = { x: 1, name: "b" }
print(a == b)
