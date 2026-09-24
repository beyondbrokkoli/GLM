-- EXPECT: 42
-- EXPECT: 0
-- FIXED by the lifecycle-parity strike (was 1): the record r now
-- frees at block exit and inner_tbl is freed as its own Table local,
-- so the block nets zero. The deep-free flag stays unset (data holds
-- a named identifier, not an inline constructor — ownership belongs
-- to inner_tbl's own binding; flagging it would double-free).
-- Field access note: r[0][0] prints because field 0 holds the table;
-- non-first fields remain unprintable (BS-2 family, unfixed).
do
  local inner_tbl = { 42 }
  local r = { data: inner_tbl, label: "nested" }
  print(r[0][0])
end
print(sys_alloc_count())
