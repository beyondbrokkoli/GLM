-- EXPECT: 1
-- EXPECT: 10
-- EXPECT: 2
local t = {1, 2, 3}
print(t[0])
do
  local big = {10, 20, 30, 40, 50}
  print(big[0])
end
print(t[1])
