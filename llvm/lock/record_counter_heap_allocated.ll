declare ptr @glm_tbl_new(i64, i8)
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
  %ts0.valp = alloca i64
  %ts1.valp = alloca i64
  br label %b0

b0:
  %v1 = add i64 0, 100
  %v2 = add i64 0, 200
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  store i64 %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v3, ptr %ts0.valp)
  %v4 = add i64 0, 1
  store i64 %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  %v6 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v6)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
