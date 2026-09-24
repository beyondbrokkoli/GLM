-- EXPECT: 0
-- FIXED by the deep-free preservation strike (was 1, BS-4). Shape's
-- child_sites fast path no longer strips Record-ness from records
-- with inline table fields, so the record keeps its Record type, the
-- block-exit free covers it (lifecycle strike), and the deep-free
-- flag is computed from the real field types (data is an inline
-- TableCtor) — the child table frees with the parent.
do
  local b = { data: { 1, 2, 3 } }
end
print(sys_alloc_count())
