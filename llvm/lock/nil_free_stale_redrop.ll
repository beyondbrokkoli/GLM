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
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = add i64 0, 5
  store i64 %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v4 = add i64 0, 0
  br label %b1

b1:
  %v5 = phi ptr [ %v0, %b0 ], [ %v10, %b2 ]
  %v6 = phi i64 [ %v4, %b0 ], [ %v11, %b2 ]
  %v9 = add i64 0, 1
  %v7 = icmp slt i64 %v6, %v9
  br i1 %v7, label %b2, label %b3

b2:
  call void @glm_tbl_free(ptr %v5)
  %v10 = inttoptr i64 0 to ptr
  %v13 = add i64 0, 1
  %v11 = add i64 %v6, %v13
  br label %b1

b3:
  %v14 = inttoptr i64 0 to ptr
  %v16 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v16)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
