-- glm/cases/record_basics.lua — combo: record construction and
-- positional access — canonical slot order, first-field-typed writes
-- (the sound direction), mixed field round-trips, documented
-- wrong-but-current baselines. Each case below is a former standalone
-- positive case, isolated in its own do-block; the EXPECT pins
-- concatenate in file order.

-- record_positional_slots.lua: field names decide the positional slot
-- order after canonicalization: fields are sorted alphabetically at
-- parse time, so slot i holds the i-th alphabetical field.
-- EXPECT: a	1
do
local r = { x: 1, name: "a" }
print(r[0], r[1])
end

-- record_positional_write_field0.lua: positional write to slot 0
-- works. After canonicalization slot 0 is the alphabetically-first
-- field (name:Str), so the write takes a String; x is untouched in
-- slot 1.
-- EXPECT: renamed	10
do
local p = { x: 10, name: "init" }
p[0] = "renamed"
print(p[0], p[1])
end

-- record_mixed_field_types.lua: mixed Int/Flt/Bool/Str fields in one
-- record round-trip exactly through the forced i64 slots (per-field
-- bitcast at load/store). Canonical slot order: flag, name, x, y.
-- EXPECT: true	s	1	2.5
do
local r = { x: 1, y: 2.5, flag: true, name: "s" }
print(r[0], r[1], r[2], r[3])
end

-- record_duplicate_keys.lua: BASELINE: wrong-but-current. Duplicate
-- keys are silently accepted and become two positional slots
-- (slot 0 = 1, slot 1 = 2). Lua semantics would be last-wins with a
-- single field.
-- EXPECT: 1	2
do
local a = { x: 1, x: 2 }
print(a[0], a[1])
end

-- record_empty_literal_is_table.lua: {} parses as an empty ARRAY
-- table, never a record: the record grammar needs Identifier ':'
-- lookahead, which empty braces lack (src/parser.rs:359-367).
-- EXPECT: 10
do
local t = {}
t[0] = 10
print(t[0])
end

-- record_read_before_store_flow_insensitive.lua: BASELINE: current
-- behavior, documented. Typing is flow-insensitive: a read textually
-- before the only store still acquires the store's element type and
-- compiles; the early read sees the zeroed slot. (With no store
-- anywhere, table_undecided.lua's panic fires.)
-- EXPECT: 0
-- EXPECT: 5
do
local m = {}
print(m[0])
m[0] = 5
print(m[0])
end

-- record_positional_oob_zero_fill.lua: BASELINE: current behavior,
-- documented. p[2] on a 2-field record reads zeroed padding (span_grow
-- floor of 8 cells, rt.rs:266); p[-1] zero-fills via the dense bounds
-- check (rt.rs:226-229). There is no phantom stack read: absence reads
-- as integer zero.
-- EXPECT: 0
-- EXPECT: 20
-- EXPECT: 0
do
local p = { x: 10, y: 20 }
print(p[2])
print(p[1])
print(p[-1])
end
