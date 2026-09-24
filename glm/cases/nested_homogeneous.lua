-- EXPECT: 42
-- EXPECT: 2
-- EXPECT: 3
-- EXPECT: 4
-- EXPECT: 8
-- Pass case: 2D integer matrix, constructor + cell mutation
local m = {{1, 2}, {3, 4}}
m[0][0] = 42
print(m[0][0])
print(m[0][1])
print(m[1][0])
print(m[1][1])
print(#m)
