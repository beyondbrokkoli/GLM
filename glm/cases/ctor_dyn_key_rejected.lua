-- ctor_dyn_key_rejected.lua
-- Constructor keys must be constant non-negative integers: a dynamic
-- key would make the literal's layout (and its slot-uniqueness proof)
-- a runtime property. {[i] = v}, {["k"] = v} and {[-1] = v} all land
-- here.
-- EXPECT_BUILD_FAIL: Syntax Error: constructor keys must be constant non-negative integers
local i = 0
local t = {[i] = 1}
print(t[0])
