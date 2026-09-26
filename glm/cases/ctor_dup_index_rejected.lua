-- ctor_dup_index_rejected.lua
-- A slot written twice in one constructor is a build error. Lua's
-- last-wins is deliberately NOT glm's rule: a silent overwrite inside a
-- literal is exactly where heterogeneous shapes used to hide. Both the
-- positional/explicit collision and [0] twice land here.
-- EXPECT_BUILD_FAIL: Syntax Error: duplicate index 0
local t = {10, [0] = 5}
print(t[0])
