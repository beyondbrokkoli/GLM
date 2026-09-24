declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_free(ptr)
declare void @glm_tbl_get(ptr, i64, ptr)
declare void @glm_tbl_set(ptr, i64, ptr)
declare i64 @glm_tbl_len(ptr)
declare void @glm_print_int(i64)
declare void @glm_print_float(double)
declare void @glm_print_bool(i1)
declare void @glm_print_string(ptr)
declare void @glm_print_sep()
declare void @glm_print_nl()

define i32 @main() {
entry:
  %ts0.valp = alloca i64
  %ts1.dst = alloca i64
  %ts2.valp = alloca i64
  %ts3.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = add i64 0, 7
  store i64 %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v4 = getelementptr i8, ptr %v0, i64 0
  %v5 = inttoptr i64 0 to ptr
  %v8 = add i64 0, 0
  call void @glm_tbl_get(ptr %v4, i64 %v8, ptr %ts1.dst)
  %v6 = load i64, ptr %ts1.dst
  call void @glm_print_int(i64 %v6)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v4)
  %v9 = inttoptr i64 0 to ptr
  %v10 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v12 = add i64 0, 1
  %v13 = add i64 0, 9
  store i64 %v13, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v10, i64 %v12, ptr %ts2.valp)
  %v16 = add i64 0, 1
  call void @glm_tbl_get(ptr %v10, i64 %v16, ptr %ts3.dst)
  %v14 = load i64, ptr %ts3.dst
  %v17 = call i64 @glm_tbl_len(ptr %v10)
  call void @glm_print_int(i64 %v14)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v17)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
