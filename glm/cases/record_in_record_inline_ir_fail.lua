-- EXPECT: a
-- EXPECT: 2
-- FIXED by the coercion strike (was EXPECT_BUILD_FAIL: invalid LLVM IR,
-- '%v1' defined with type 'ptr' but expected 'i64', BS-3): record
-- values are now ptrtoint'ed into the i64 slot via record_regs, so a
-- record field can hold a record and the read chain a[0][0]
-- round-trips (slot 0 of the canonicalized inner record is name).
-- BASELINE on the counter: 2 allocations, 0 frees — the outer record
-- is immortal at block exit (BS-1) and its deep-free flag is unset
-- (BS-4), so the inner record leaks too. Strikes 3 and 4 close this.
do
  local a = { inner: { x: 1, name: "a" } }
  print(a[0][0])
end
print(sys_alloc_count())
