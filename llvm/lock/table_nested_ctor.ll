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
  %ts0.valp = alloca ptr
  %ts1.dst = alloca ptr
  %ts2.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v1 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  store ptr %v0, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v1, i64 %v3, ptr %ts0.valp)
  %v7 = add i64 0, 0
  call void @glm_tbl_get(ptr %v1, i64 %v7, ptr %ts1.dst)
  %ts1.loaded = load i64, ptr %ts1.dst
%v5 = inttoptr i64 %ts1.loaded to ptr
  %v8 = add i64 0, 0
  call void @glm_tbl_get(ptr %v5, i64 %v8, ptr %ts2.dst)
  %v4 = load i64, ptr %ts2.dst
  call void @glm_print_int(i64 %v4)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
