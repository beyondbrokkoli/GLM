-- EXPECT_BUILD_FAIL: defined with type 'ptr' but expected 'i64'
-- BS-3: a record field holding a record crashes codegen with
-- invalid LLVM IR. Record registers are typed Integer in reg_types
-- (backend.rs:173), so TableSet's cast selection skips ptrtoint and
-- stores the raw ptr into an i64 slot. The named-variable form
-- (local inner = {x:1}; local r = {copy: inner}) fails identically.
do
  local a = { inner: { x: 1, name: "a" } }
end
