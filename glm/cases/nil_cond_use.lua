-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
-- A drop under an if poisons the name for the rest of the scope: the
-- merge carries null in t's possible set, so the later read is
-- possibly-nil and rejected — glm refuses at compile time what Lua
-- would only maybe reject at run time. That strictness is the price
-- of a check-free hot path.
local t = {}
t[0] = 1
if 2 > 3 then
    t = nil
end
print(t[0])
