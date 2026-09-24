-- EXPECT: 1.5	8	2.5
-- First touch decides: '{}' becomes a FloatTable when the first value
-- stored through any alias is a Float. Strict typing — a later Integer
-- store into the same table is still an error (float_table_store_int).
local t = {}
t[0] = 1.5
local u = t
u[1] = 2.5
print(t[0], #t, u[1])
