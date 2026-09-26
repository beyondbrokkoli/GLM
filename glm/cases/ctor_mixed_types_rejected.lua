-- ctor_mixed_types_rejected.lua
-- Strict per-layer typing: elements inside one constructor must be one
-- type. Int and String in the same layer is the loud refusal — there is
-- no coercion and no mixed layout behind it (the record machinery that
-- used to absorb this is removed).
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
local t = {1, "x"}
print(t[0])
