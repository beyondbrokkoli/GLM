-- EXPECT: negative
-- EXPECT: zero
-- EXPECT: positive
-- EXPECT: 5
-- EXPECT: 5
-- EXPECT: 100
-- EXPECT: 1
-- EXPECT: true
-- Control flow: if/elseif/else chains, while with and/or condition,
-- short-circuit lowering, scope shadowing.

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
