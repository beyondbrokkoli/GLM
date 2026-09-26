-- EXPECT: 1
-- EXPECT_PANIC: glm: table allocation of 18446744073709551615 bytes failed
-- BASELINE: wrong-but-current — RUNTIME ABORT (exit 134), not 1.
-- Intra-block aliasing double-free at do-exit: `local b = c` binds b
-- to the SAME register (pointer) as c; scope exit emits TableFree for
-- every block-local of owned heap type, so the one table is freed
-- twice. The second glm_tbl_free re-boxes freed memory, the garbage
-- header's len overflows elem_layout, and the allocator aborts
-- ("table allocation of 18446744073709551615 bytes failed"). No bare
-- locals involved — pre-existing since the do-exit free; found while
-- probing bare-local spelling. The drop_reference sole-ownership proof
-- (A.1) exists for explicit t = nil but scope-exit emission has no
-- alias awareness. Pinning as the map entry for the ownership gap.
do
  local c = {}
  c[0] = 1
  local b = c
  print(sys_alloc_count())
end
print(sys_alloc_count())
