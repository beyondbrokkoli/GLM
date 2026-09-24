-- EXPECT_BUILD_FAIL: heterogeneous tables are not supported
-- Positional arrays with mixed element types still fail the homogeneous check.
-- Records (using {k: v} syntax) are the correct way to build heterogeneous data.
local a = {1, "mismatch"}
