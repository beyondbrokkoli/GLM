-- ctor_named_key_rejected.lua
-- {name = v} parses (it is Lua) but named string keys are not supported
-- yet — string-keyed cells need a hashing runtime and an ownership
-- story. The rejection names the replacement form.
-- EXPECT_BUILD_FAIL: Syntax Error: named keys
local t = {x = 1}
print(t[0])
