-- ctor_nested_mixed_rejected.lua
-- Tables are containers, not elements — but containers still agree on
-- their element type: a layer of tables whose layers disagree (Int row
-- vs String row) is mixed typing, refused like a scalar mix.
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
local t = { {1}, {"x"} }
print(t[0][0])
