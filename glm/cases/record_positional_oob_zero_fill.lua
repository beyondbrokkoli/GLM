-- EXPECT: 0
-- EXPECT: 20
-- EXPECT: 0
-- BASELINE: current behavior, documented. p[2] on a 2-field record
-- reads zeroed padding (span_grow floor of 8 cells, rt.rs:266);
-- p[-1] zero-fills via the dense bounds check (rt.rs:226-229).
-- There is no phantom stack read: absence reads as integer zero.
local p = { x: 10, y: 20 }
print(p[2])
print(p[1])
print(p[-1])
