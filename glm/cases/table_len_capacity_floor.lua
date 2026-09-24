-- EXPECT: 8
-- EXPECT: 0
-- BASELINE: wrong-but-current. #t is the allocated span length with
-- a floor of 8 (span_grow: max(want, 2*len, 8), rt.rs:266), not the
-- element count: one store to m[0] makes #m == 8. An untouched
-- table has len 0.
local m = {}
m[0] = 1
print(#m)
local n = {}
print(#n)
