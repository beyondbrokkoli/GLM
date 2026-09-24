-- EXPECT_BUILD_FAIL: table index overflow
local t = {}
local i = 0
while i < 1000 do
    t[i] = i
    i = i + 1
end
t[9223372036854775807] = 42
print(#t)        -- Force a read of the table header
print(t[0])      -- Force a read of the data buffer (prevents DCE)

