@.str.0 = private unnamed_addr constant [2 x i8] c"a\00"
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
  %ts2.valp = alloca ptr
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v4 = getelementptr inbounds [2 x i8], ptr @.str.0, i64 0, i64 0
  %v5 = add i64 0, 1
  %v3 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v6 = add i64 0, 0
  %ts0.cast = ptrtoint ptr %v4 to i64
store i64 %ts0.cast, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v3, i64 %v6, ptr %ts0.valp)
  %v7 = add i64 0, 1
  store i64 %v5, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v3, i64 %v7, ptr %ts1.valp)
  store ptr %v3, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts2.valp)
  call void @glm_tbl_free(ptr %v0)
  %v9 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v9)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
