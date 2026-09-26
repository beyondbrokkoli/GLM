-- EXPECT_BUILD_FAIL: defined with type 'ptr' but expected 'i64'
-- print(x) on a bare local that was never assigned: the checker types
-- it Unknown (print gate passes), the lowerer reads the null register,
-- and the backend emits glm_print_int(i64 %vN) against the LoadNull
-- register, which is typed ptr — clang rejects. Same IR-cast family as
-- record_equality_compare_ir_fail.lua (C.4): the null register has no
-- print coercion. Assign-then-print works (bare_local_alias_bind.lua);
-- only the never-assigned read trips this.
local x
print(x)
