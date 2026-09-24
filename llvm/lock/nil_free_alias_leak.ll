@.str.0 = private unnamed_addr constant [7 x i8] c"leaked\00"
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
  %ts2.valp = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = add i64 0, 1
  store i64 %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v4 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v6 = add i64 0, 0
  %v7 = add i64 0, 2
  store i64 %v7, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v4, i64 %v6, ptr %ts1.valp)
  %v8 = getelementptr i8, ptr %v0, i64 0
  %v9 = or i1 0, 0
  br i1 %v9, label %b1, label %b2

b1:
  %v10 = getelementptr i8, ptr %v4, i64 0
  br label %b3

b2:
  br label %b3

b3:
  %v11 = phi ptr [ %v10, %b1 ], [ %v8, %b2 ]
  %v13 = add i64 0, 0
  %v14 = add i64 0, 5
  store i64 %v14, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v11, i64 %v13, ptr %ts2.valp)
  %v15 = inttoptr i64 0 to ptr
  %v17 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v17)
  call void @glm_print_nl()
  %v18 = getelementptr inbounds [7 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v18)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
