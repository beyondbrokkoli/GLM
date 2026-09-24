-- EXPECT: 1	a
-- Field order in the constructor literal IS the positional slot order:
-- slot i holds the i-th field, independent of field name.
local r = { x: 1, name: "a" }
print(r[0], r[1])
