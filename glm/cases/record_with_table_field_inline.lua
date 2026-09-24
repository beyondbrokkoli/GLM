-- EXPECT: 1
-- BASELINE: wrong-but-current (BS-4). A record with an inline table
-- field is retyped Table(Table(Int)) by shape's child_sites fast
-- path (shape.rs:287-310): the block-exit free fires for the record
-- header, but the deep-free flag computes from the retyped element,
-- no longer matches Record(_), and drops bit 0x80 — the child
-- table leaks. Net: 2 allocations, 1 free, counter 1.
do
  local b = { data: { 1, 2, 3 } }
end
print(sys_alloc_count())
