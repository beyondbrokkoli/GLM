-- EXPECT_BUILD_FAIL: type conflict
-- First-field typing (BS-5, unfixed): every record index is checked
-- against field 0's type only. After canonicalization field 0 is
-- name:Str, so an Int write to slot 1 panics. (The mirror hole —
-- Str writes into the x:Int slot — is compile-accepted; see
-- record_positional_write_wrong_slot_accepted.)
local p = { x: 10, name: "init" }
p[1] = 5
