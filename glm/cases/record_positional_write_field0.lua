-- EXPECT: 5	init
-- Positional write to slot 0 is checked against field 0's type and
-- succeeds; other fields are untouched.
local p = { x: 10, name: "init" }
p[0] = 5
print(p[0], p[1])
