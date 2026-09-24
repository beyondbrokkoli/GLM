-- EXPECT: 1	2.5	true	s
-- Mixed Int/Flt/Bool/Str fields in one record round-trip exactly
-- through the forced i64 slots (per-field bitcast at load/store).
local r = { x: 1, y: 2.5, flag: true, name: "s" }
print(r[0], r[1], r[2], r[3])
