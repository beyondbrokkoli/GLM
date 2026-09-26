-- ctor_scalar_table_mix_rejected.lua
-- A scalar and a table in the same layer is heterogeneous: the layer
-- cannot be a monomorphic array and there is no record layout to catch
-- it anymore — refused loudly.
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
local t = {1, {2}}
print(t[0])
