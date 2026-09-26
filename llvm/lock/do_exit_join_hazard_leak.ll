declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_free(ptr)
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
  %ts0.valp = alloca i64
  %ts1.valp = alloca i64
  %ts2.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = add i64 0, 3
  store i64 %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v5 = add i64 0, 1
  %v6 = add i64 0, 2
  %v4 = icmp slt i64 %v5, %v6
  br i1 %v4, label %b1, label %b2

b1:
  %v7 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v9 = add i64 0, 0
  %v10 = add i64 0, 4
  store i64 %v10, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v7, i64 %v9, ptr %ts1.valp)
  %v11 = getelementptr i8, ptr %v7, i64 0
  br label %b3

b2:
  br label %b3

b3:
  %v12 = phi ptr [ %v11, %b1 ], [ %v0, %b2 ]
  %v15 = add i64 0, 0
  call void @glm_tbl_get(ptr %v12, i64 %v15, ptr %ts2.dst)
  %v13 = load i64, ptr %ts2.dst
  call void @glm_print_int(i64 %v13)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v0)
  %v17 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v17)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
