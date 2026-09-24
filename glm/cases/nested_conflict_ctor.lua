-- EXPECT: hero	0
-- Canonicalized record slots: fields are sorted alphabetically at
-- parse time, so slot 0 = name, slot 1 = x (pre-canonicalization
-- golden was '0\thero').
local player = { x: 0, name: "hero" }
print(player[0], player[1])
