declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_free(ptr)
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
  %ts2.valp = alloca i64
  %ts3.valp = alloca i64
  br label %b0

b0:
  %v2 = add i64 0, 1
  %v3 = add i64 0, 2
  %v4 = add i64 0, 3
  %v1 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v5 = add i64 0, 0
  store i64 %v2, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v1, i64 %v5, ptr %ts0.valp)
  %v6 = add i64 0, 1
  store i64 %v3, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v1, i64 %v6, ptr %ts1.valp)
  %v7 = add i64 0, 2
  store i64 %v4, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v1, i64 %v7, ptr %ts2.valp)
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v8 = add i64 0, 0
  %ts3.cast = ptrtoint ptr %v1 to i64
store i64 %ts3.cast, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v0, i64 %v8, ptr %ts3.valp)
  call void @glm_tbl_free(ptr %v0)
  %v10 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v10)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
