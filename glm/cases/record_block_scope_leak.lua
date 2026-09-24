-- EXPECT: 1
-- EXPECT: 1
-- BASELINE: wrong-but-current (BS-1 Record Immortality). The
-- do-block exit free filters locals on StaticType::Table(_)
-- (lowerer.rs:408); a record local fails the filter and leaks, so
-- the counter never returns to 0: the record block leaves +1 and
-- the table block below nets zero (allocates t, frees t at block
-- exit). Standalone control: a table-only block prints 0 (the
-- block-exit free is real — visible as glm_tbl_free in its IR).
do
  local r = { x: 1, name: "a" }
end
print(sys_alloc_count())
do
  local t = {}
  t[0] = 1
end
print(sys_alloc_count())
