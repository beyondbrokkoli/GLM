declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_reserve(ptr, i64)
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
  %ts1.dst = alloca double
  %ts2.valp = alloca double
  %ts3.dst = alloca double
  %ts4.dst = alloca double
  %ts5.valp = alloca i64
  %ts6.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v1 = getelementptr i8, ptr %v0, i64 0
  %v3 = add i64 0, 0
  %v4 = fadd double 0.0, 1.5
  store double %v4, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v1, i64 %v3, ptr %ts0.valp)
  %v7 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v7, ptr %ts1.dst)
  %v5 = load double, ptr %ts1.dst
  call void @glm_print_float(double %v5)
  call void @glm_print_nl()
  %v8 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v10 = add i64 0, 1
  %v11 = add i64 0, 2
  %v9 = icmp slt i64 %v11, %v10
  br i1 %v9, label %b1, label %b2

b1:
  %v12 = call ptr @glm_tbl_new(i64 8, i8 0)
  br label %b3

b2:
  %v13 = getelementptr i8, ptr %v0, i64 0
  br label %b3

b3:
  %v14 = phi ptr [ %v12, %b1 ], [ %v13, %b2 ]
  %v16 = add i64 0, 1
  %v17 = fadd double 0.0, 2.5
  store double %v17, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v14, i64 %v16, ptr %ts2.valp)
  %v20 = add i64 0, 1
  call void @glm_tbl_get(ptr %v14, i64 %v20, ptr %ts3.dst)
  %v18 = load double, ptr %ts3.dst
  %v23 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v23, ptr %ts4.dst)
  %v21 = load double, ptr %ts4.dst
  call void @glm_print_float(double %v18)
  call void @glm_print_sep()
  call void @glm_print_float(double %v21)
  call void @glm_print_nl()
  %v24 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v25 = add i64 0, 0
  %v26 = add i64 0, 8
  call void @glm_tbl_reserve(ptr %v24, i64 %v26)
  br label %b4

b4:
  %v27 = phi i64 [ %v25, %b3 ], [ %v32, %bts5cont ]
  %v28 = icmp slt i64 %v27, %v26
  br i1 %v28, label %b5, label %b6

b5:
%ts5.d = load ptr, ptr %v24, !alias.scope !0
%ts5.s = getelementptr inbounds i64, ptr %ts5.d, i64 %v27
store i64 %v27, ptr %ts5.s, !noalias !0
br label %bts5cont

bts5cont:
  %v34 = add i64 0, 1
  %v32 = add i64 %v27, %v34
  br label %b4

b6:
  %v37 = add i64 0, 7
  call void @glm_tbl_get(ptr %v24, i64 %v37, ptr %ts6.dst)
  %v35 = load i64, ptr %ts6.dst
  %v38 = call i64 @glm_tbl_len(ptr %v24)
  call void @glm_print_int(i64 %v35)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v38)
  call void @glm_print_nl()
  %v40 = call ptr @glm_tbl_new(i64 1, i8 0)
  %v41 = call i64 @glm_tbl_len(ptr %v40)
  call void @glm_print_int(i64 %v41)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
