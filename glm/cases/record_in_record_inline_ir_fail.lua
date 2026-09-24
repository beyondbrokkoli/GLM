-- EXPECT: a
-- EXPECT: 1
-- FIXED by the coercion strike (was EXPECT_BUILD_FAIL: invalid LLVM
-- IR, BS-3): nested record round-trip a[0][0] == 'a'.
-- Counter after the lifecycle-parity strike: the outer record frees
-- at block exit (was 2), but the inner record still leaks — the
-- deep-free flag is unset for nested RECORD fields (BS-4, closed by
-- the next strike). Baseline was 2; now 1; target is 0.
do
  local a = { inner: { x: 1, name: "a" } }
  print(a[0][0])
end
print(sys_alloc_count())
