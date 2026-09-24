-- EXPECT: 1
-- EXPECT: 2
-- EXPECT: 3
-- EXPECT: 4
-- Nested tables test: 2D matrix via constructor
local mat = {{1, 2}, {3, 4}}
print(mat[0][0])
print(mat[0][1])
print(mat[1][0])
print(mat[1][1])
