-- record_nil_drop_rejected.lua: former record nil-release parity pin
--
-- RECORD SYNTAX GUARD: the {k: v} spelling was removed with the record
-- machinery (named-key constructors and mixed-type layouts are
-- not glm's model). The parse must reject it here —
-- re-acceptance of the colon form is the regression this pin catches.
-- EXPECT_BUILD_FAIL: Syntax Error: record syntax
do
local r = { x: 1, name: "a" }
r = nil
end
