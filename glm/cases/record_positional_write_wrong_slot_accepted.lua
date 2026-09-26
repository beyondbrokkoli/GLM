-- record_positional_write_wrong_slot_accepted.lua: former BS-5 unsound-write bug pin
--
-- RECORD SYNTAX GUARD: the {k: v} spelling was removed with the record
-- machinery (named-key constructors and mixed-type layouts are
-- not glm's model). The parse must reject it here —
-- re-acceptance of the colon form is the regression this pin catches.
-- EXPECT_BUILD_FAIL: Syntax Error: record syntax
do
local p = { x: 10, name: "init" }
p[1] = "s"
print(p[1])
end
