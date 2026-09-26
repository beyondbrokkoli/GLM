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
  br label %b0

b0:
  %v0 = inttoptr i64 0 to ptr
  %v2 = add i64 0, 1
  %v3 = add i64 0, 2
  %v1 = icmp slt i64 %v2, %v3
  br i1 %v1, label %b1, label %b2

b1:
  %v4 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v6 = add i64 0, 0
  %v7 = add i64 0, 7
  store i64 %v7, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v4, i64 %v6, ptr %ts0.valp)
  %v8 = getelementptr i8, ptr %v4, i64 0
  br label %b3

b2:
  br label %b3

b3:
  %v9 = phi ptr [ %v8, %b1 ], [ %v0, %b2 ]
  call void @glm_tbl_free(ptr %v9)
  %v11 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v11)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
