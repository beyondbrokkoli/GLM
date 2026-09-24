-- EXPECT: 6	2
-- Table-typed if-phis make 'pick' possibly-bound to either root, so
-- 'pick = nil' can free neither (it unhooks); both originals stay
-- usable through their own names. Conditional aliasing is legal — the
-- ambiguity routes itself into the unhook bucket.
local a = {}
a[0] = 1
local b = {}
b[0] = 2
local pick = a
if 1 > 2 then
    pick = b
end
pick[0] = 5
pick = nil
a[0] = a[0] + 1
print(a[0], b[0])
