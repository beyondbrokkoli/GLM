-- ctor_int_float_mix_rejected.lua
-- Int and Float do not unify inside a constructor (same strictness as
-- arithmetic operands): the layer must pick one scalar type.
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
local t = {1, 2.5}
print(t[0])
