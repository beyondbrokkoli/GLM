-- EXPECT_BUILD_FAIL: Type Error: type conflict — String vs Integer
-- BS-5 mirror, kept standalone: after canonicalization field 0 is
-- name:Str, and check_index_base types EVERY record index with field
-- 0's type, so the Int write to slot 1 is rejected. (The accepted half
-- of the hole — a Str into the x:Int slot — is
-- record_positional_write_wrong_slot_accepted.lua; the read-back
-- disclosure is ASLR-nondeterministic and unpinnable, see
-- docs/records_and_memory.md BS-5.)
local p = { x: 10, name: "init" }
p[1] = 5
