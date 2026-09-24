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
  %ts2.valp = alloca i64
  %ts3.dst = alloca i64
  %ts4.valp = alloca i64
  %ts5.dst = alloca i64
  %ts6.dst = alloca i64
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
  %v10 = add i64 0, 1
  %v11 = add i64 0, 2
  %v9 = icmp slt i64 %v11, %v10
  br i1 %v9, label %b1, label %b2

b1:
  %v12 = getelementptr i8, ptr %v4, i64 0
  br label %b3

b2:
  br label %b3

b3:
  %v13 = phi ptr [ %v12, %b1 ], [ %v8, %b2 ]
  %v15 = add i64 0, 0
  %v16 = add i64 0, 5
  store i64 %v16, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v13, i64 %v15, ptr %ts2.valp)
  %v17 = inttoptr i64 0 to ptr
  %v19 = add i64 0, 0
  %v23 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v23, ptr %ts3.dst)
  %v21 = load i64, ptr %ts3.dst
  %v24 = add i64 0, 1
  %v20 = add i64 %v21, %v24
  store i64 %v20, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v0, i64 %v19, ptr %ts4.valp)
  %v27 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v27, ptr %ts5.dst)
  %v25 = load i64, ptr %ts5.dst
  %v30 = add i64 0, 0
  call void @glm_tbl_get(ptr %v4, i64 %v30, ptr %ts6.dst)
  %v28 = load i64, ptr %ts6.dst
  call void @glm_print_int(i64 %v25)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v28)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
