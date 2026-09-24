-- EXPECT: true
-- EXPECT: false
-- EXPECT: true
-- EXPECT: false
-- EXPECT: false
-- Pillar 3: booleans — and/or/not, equality, loop-carried bool phi.

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
