-- record_permuted_keys_conflict.lua: former permuted-field-order join pin
--
-- RECORD SYNTAX GUARD: the {k: v} spelling was removed with the record
-- machinery (named-key constructors and mixed-type layouts are
-- not glm's model). The parse must reject it here —
-- re-acceptance of the colon form is the regression this pin catches.
-- EXPECT_BUILD_FAIL: Syntax Error: record syntax
local a = { name: "alpha", x: 1 }
local b = { x: 2, name: "beta" }
print(a[0], b[0])
