-- EXPECT: a
-- EXPECT: 0
-- FIXED by the coercion + lifecycle + deep-free strikes (was a
-- build-fail pin: invalid LLVM IR from the missing ptrtoint; then
-- stepwise counter leaks of 2, then 1). Nested record round-trip
-- a[0][0] == 'a'; the outer record frees at block exit with the
-- deep-free flag set (inline Record field), so the inner record is
-- freed too — the counter returns to 0.
do
  local a = { inner: { x: 1, name: "a" } }
  print(a[0][0])
end
print(sys_alloc_count())
