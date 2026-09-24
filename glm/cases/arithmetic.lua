-- EXPECT: 60
-- EXPECT: -7
-- EXPECT: 3
-- EXPECT: 1
-- EXPECT: 5
-- EXPECT: 3.5
-- EXPECT: -4
-- EXPECT: -4
-- EXPECT: 3
-- EXPECT: 1
-- EXPECT: -1
-- EXPECT: -1
-- EXPECT: 0
-- EXPECT: -4
-- EXPECT: -4
-- EXPECT: 0.5
-- EXPECT: -0.5
-- EXPECT: -1.5
-- EXPECT: 6
-- Pillars 1 & 2: integer and float arithmetic.

local a = 10
local b = 25
print(a + b * 2)
print(-b + 18)
print(7 // 2)
print(7 % 2)

local x = 2.5
print(x * 2.0)
print(7.0 / 2.0)

-- Lua arithmetic law: '//' rounds toward -infinity and '%' takes the
-- divisor's sign — on floats too. (glm prints floats shortest-roundtrip,
-- so -4.0 shows up as -4 above.)
print(-7 // 2)
print(7 // -2)
print(-7 // -2)
print(-7 % 2)
print(7 % -2)
print(-7 % -2)
print(6 % -3)
print(-7.5 // 2.0)
print(7.5 // -2.0)
print(-7.5 % 2.0)
print(7.5 % -2.0)
print(-7.5 % -2.0)

-- loop-carried integer phi
local sum = 0
local i = 1
while i <= 5 do
    if i % 2 == 0 then
        sum = sum + i
    end
    i = i + 1
end
print(sum)
