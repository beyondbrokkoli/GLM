-- EXPECT: Hello, glm!
-- EXPECT: tab	joined
-- EXPECT: second
-- Pillar 4: strings as C pointers. Literals only — concat, indexing and
-- comparison arrive with a future horizontal pass.

local greeting = "Hello, glm!"
print(greeting)
print("tab", "joined")

-- string phi: picking between two literals across a branch
local pick = "first"
if 1 > 2 then
    pick = "first"
else
    pick = "second"
end
print(pick)
