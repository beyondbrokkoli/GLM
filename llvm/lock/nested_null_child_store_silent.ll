declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_get(ptr, i64, ptr)
declare void @glm_tbl_set(ptr, i64, ptr)
declare i64 @sys_alloc_count()
declare void @glm_print_int(i64)
declare void @glm_print_float(double)
declare void @glm_print_bool(i1)
declare void @glm_print_string(ptr)
declare void @glm_print_sep()
declare void @glm_print_nl()

define i32 @main() {
entry:
  %ts0.dst = alloca ptr
  %ts1.valp = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v3, ptr %ts0.dst)
  %v1 = load ptr, ptr %ts0.dst
  %v4 = add i64 0, 0
  %v5 = add i64 0, 5
  store i64 %v5, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v1, i64 %v4, ptr %ts1.valp)
  %v7 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v7)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
