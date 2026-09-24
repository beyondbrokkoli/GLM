-- EXPECT_BUILD_FAIL: type conflict
-- Positional writes are typed against field 0 only: p[1] = "s" is
-- checked as Int (field x's type) vs String and panics. The write
-- is asymmetric: wrong-typed writes are caught only when they don't
-- match field 0 (see record_positional_write_wrong_slot_accepted).
local p = { x: 10, name: "init" }
p[1] = "mutated"
