declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_get(ptr, i64, ptr)
declare void @glm_tbl_set(ptr, i64, ptr)
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
  %ts2.dst = alloca i64
  %ts3.dst = alloca i64
  %ts4.dst = alloca i64
  br label %b0

b0:
  %v1 = add i64 0, 10
  %v2 = add i64 0, 20
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  store i64 %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v3, ptr %ts0.valp)
  %v4 = add i64 0, 1
  store i64 %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  %v7 = add i64 0, 2
  call void @glm_tbl_get(ptr %v0, i64 %v7, ptr %ts2.dst)
  %v5 = load i64, ptr %ts2.dst
  call void @glm_print_int(i64 %v5)
  call void @glm_print_nl()
  %v10 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v10, ptr %ts3.dst)
  %v8 = load i64, ptr %ts3.dst
  call void @glm_print_int(i64 %v8)
  call void @glm_print_nl()
  %v14 = add i64 0, 1
  %v13 = sub i64 0, %v14
  call void @glm_tbl_get(ptr %v0, i64 %v13, ptr %ts4.dst)
  %v11 = load i64, ptr %ts4.dst
  call void @glm_print_int(i64 %v11)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
