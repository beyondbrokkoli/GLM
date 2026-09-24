-- EXPECT: 1
-- BASELINE: wrong-but-current. The outer table is Table-typed and is
-- freed at do-block exit; the stored record is not (records are not
-- deep-free children: TableCtor's contains_tables check matches
-- Table(_) element types only, and Record(_) fails it).
do
  local m = {}
  m[0] = { x: 1, name: "a" }
end
print(sys_alloc_count())
