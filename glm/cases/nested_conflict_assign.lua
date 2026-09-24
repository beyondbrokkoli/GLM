-- EXPECT: 1	hello	2	world
-- Records with matching keys but mixed field types compile cleanly.
-- Each record in the table has the same shape {x: Int, name: Str}.
local m = {}
m[0] = {x: 1, name: "hello"}
m[1] = {x: 2, name: "world"}
print(m[0][0], m[0][1], m[1][0], m[1][1])
