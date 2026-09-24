declare ptr @glm_tbl_new(i64, i8)
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
  %ts0.valp = alloca double
  %ts1.valp = alloca double
  %ts2.dst = alloca double
  %ts4.dst = alloca double
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = fadd double 0.0, 1.5
  store double %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v4 = getelementptr i8, ptr %v0, i64 0
  %v6 = add i64 0, 1
  %v7 = fadd double 0.0, 2.5
  store double %v7, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v4, i64 %v6, ptr %ts1.valp)
  %v10 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v10, ptr %ts2.dst)
  %v8 = load double, ptr %ts2.dst
  %v11 = call i64 @glm_tbl_len(ptr %v0)
  %v15 = add i64 0, 1
  call void @glm_tbl_get(ptr %v4, i64 %v15, ptr %ts4.dst)
  %v13 = load double, ptr %ts4.dst
  call void @glm_print_float(double %v8)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v11)
  call void @glm_print_sep()
  call void @glm_print_float(double %v13)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
