-- EXPECT: renamed	10
-- Positional write to slot 0 works. After canonicalization slot 0
-- is the alphabetically-first field (name:Str), so the write takes
-- a String; x is untouched in slot 1.
local p = { x: 10, name: "init" }
p[0] = "renamed"
print(p[0], p[1])
