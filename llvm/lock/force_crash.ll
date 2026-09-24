@.str.0 = private unnamed_addr constant [53 x i8] c"If you see this, the bullet missed the vital organs.\00"
declare ptr @glm_tbl_new(i64, i8)
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
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = add i64 0, 1
  store i64 %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v4 = add i64 0, 1
  %v5 = add i64 0, 0
  br label %b1

b1:
  %v6 = phi i64 [ %v4, %b0 ], [ %v11, %b2 ]
  %v7 = phi i64 [ %v5, %b0 ], [ %v14, %b2 ]
  %v10 = add i64 0, 63
  %v8 = icmp slt i64 %v7, %v10
  br i1 %v8, label %b2, label %b3

b2:
  %v13 = add i64 0, 2
  %v11 = mul i64 %v6, %v13
  %v16 = add i64 0, 1
  %v14 = add i64 %v7, %v16
  br label %b1

b3:
  %v19 = add i64 0, 1
  %v17 = sub i64 %v6, %v19
  %v22 = add i64 0, 1099511627776
  store i64 %v22, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v17, ptr %ts1.valp)
  %v24 = add i64 0, 10
  %v25 = add i64 0, 42
  store i64 %v25, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v0, i64 %v24, ptr %ts2.valp)
  %v26 = getelementptr inbounds [53 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v26)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
