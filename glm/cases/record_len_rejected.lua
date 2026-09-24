-- EXPECT_BUILD_FAIL: '#' requires a table operand
-- #record is rejected: the Len gate matches Table(_) only
-- (type_checker.rs:347-353).
local r = { x: 1, name: "a" }
print(#r)
