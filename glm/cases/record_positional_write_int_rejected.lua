-- record_positional_write_int_rejected.lua: former BS-5 mirror rejection pin
--
-- RECORD SYNTAX GUARD: the {k: v} spelling was removed with the record
-- machinery (named-key constructors and mixed-type layouts are
-- not glm's model). The parse must reject it here —
-- re-acceptance of the colon form is the regression this pin catches.
-- EXPECT_BUILD_FAIL: Syntax Error: record syntax
do
local p = { x: 10, name: "init" }
p[1] = 5
end
