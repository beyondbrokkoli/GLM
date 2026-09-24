-- EXPECT: a	1
-- Field names decide the positional slot order after canonicalization:
-- fields are sorted alphabetically at parse time, so slot i holds the
-- i-th alphabetical field.
local r = { x: 1, name: "a" }
print(r[0], r[1])
