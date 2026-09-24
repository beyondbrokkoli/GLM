-- EXPECT_BUILD_FAIL: 'nil' releases tables
-- BS-1: records cannot be dropped. The nil-assignment gate requires
-- StaticType::Table (type_checker.rs:89-96) and rejects Record.
local r = { x: 1, name: "a" }
r = nil
