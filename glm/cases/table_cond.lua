-- EXPECT_BUILD_FAIL: 'while' condition must be a Boolean, got IntTable
local t = {}
while t do
    t[0] = 1
end
