-- record_in_table_first_touch_leak.lua: former BS-11 stored-record leak pin
--
-- RECORD SYNTAX GUARD: the {k: v} spelling was removed with the record
-- machinery (named-key constructors and mixed-type layouts are
-- not glm's model). The parse must reject it here —
-- re-acceptance of the colon form is the regression this pin catches.
-- EXPECT_BUILD_FAIL: Syntax Error: record syntax
do
local m = {}
m[0] = { x: 1, name: "a" }
end
print(sys_alloc_count())
