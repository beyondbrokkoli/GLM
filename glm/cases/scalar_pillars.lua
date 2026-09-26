-- glm/cases/scalar_pillars.lua — combo: the scalar pillars plus
-- control flow. Each case below is a former standalone positive case,
-- isolated in its own do-block; the EXPECT pins concatenate in file
-- order.

-- arithmetic.lua: Pillars 1 & 2: integer and float arithmetic.
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
do
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
end

-- booleans.lua: Pillar 3: booleans — and/or/not, equality, loop-carried
-- bool phi.
-- EXPECT: true
-- EXPECT: false
-- EXPECT: true
-- EXPECT: false
-- EXPECT: false
do
print(true and false or true)
print(1 < 2 and 2 < 1)

local flag = not (3 == 4)
print(flag)
print(true == false)

-- loop-carried boolean: flips once at the boundary
local on = true
local i = 0
while i < 4 do
    if i == 2 then
        on = false
    end
    i = i + 1
end
print(on)
end

-- strings.lua: Pillar 4: strings as C pointers. Literals only — concat,
-- indexing and comparison arrive with a future horizontal pass.
-- EXPECT: Hello, glm!
-- EXPECT: tab	joined
-- EXPECT: second
do
local greeting = "Hello, glm!"
print(greeting)
print("tab", "joined")

-- string phi: picking between two literals across a branch
local pick = "first"
if 1 > 2 then
    pick = "first"
else
    pick = "second"
end
print(pick)
end

-- control_flow.lua: if/elseif/else chains, while with and/or condition,
-- short-circuit lowering, scope shadowing.
-- EXPECT: negative
-- EXPECT: zero
-- EXPECT: positive
-- EXPECT: 5
-- EXPECT: 5
-- EXPECT: 100
-- EXPECT: 1
-- EXPECT: true
do
local n = -5
if n < 0 then
    print("negative")
elseif n == 0 then
    print("zero")
else
    print("positive")
end

n = 0
if n < 0 then
    print("negative")
elseif n == 0 then
    print("zero")
else
    print("positive")
end

n = 5
if n < 0 then
    print("negative")
elseif n == 0 then
    print("zero")
else
    print("positive")
end

local a = 0
local b = 10
while a < 5 and b > 5 do
    a = a + 1
    b = b - 1
end
print(a)
print(b)

local x = 1
if 0 < 1 then
    local x = 100
    print(x)
end
print(x)

print(not (1 < 0))
end
