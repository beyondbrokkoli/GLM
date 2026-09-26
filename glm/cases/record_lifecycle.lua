-- glm/cases/record_lifecycle.lua
-- combo (former): the record lifetime story — block-exit frees, deep-free of inline children, the allocation counter.
--
-- CONSTRUCTOR CUT: the record syntax this case exercised is rejected
-- at parse until the Lua-style constructor redesign lands. The case
-- stays as a guard — the k: v spelling must not silently re-accept.
-- EXPECT_BUILD_FAIL: Syntax Error: populated constructors are not supported
do
local r = { x: 1, name: "a" }
end
print(sys_alloc_count())
