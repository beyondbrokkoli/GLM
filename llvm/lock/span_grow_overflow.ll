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
  %ts0.valp = alloca i64
  %ts1.valp = alloca i64
  %ts2.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v1 = add i64 0, 0
  %v2 = add i64 0, 1000
  call void @glm_tbl_reserve(ptr %v0, i64 %v2)
  br label %b1

b1:
  %v3 = phi i64 [ %v1, %b0 ], [ %v8, %bts0cont ]
  %v4 = icmp slt i64 %v3, %v2
  br i1 %v4, label %b2, label %b3

b2:
%ts0.d = load ptr, ptr %v0, !alias.scope !0
%ts0.s = getelementptr inbounds i64, ptr %ts0.d, i64 %v3
store i64 %v3, ptr %ts0.s, !noalias !0
br label %bts0cont

bts0cont:
  %v10 = add i64 0, 1
  %v8 = add i64 %v3, %v10
  br label %b1

b3:
  %v11 = add i64 0, 1
  %v12 = add i64 0, 0
  br label %b4

b4:
  %v13 = phi i64 [ %v11, %b3 ], [ %v18, %b5 ]
  %v14 = phi i64 [ %v12, %b3 ], [ %v21, %b5 ]
  %v17 = add i64 0, 63
  %v15 = icmp slt i64 %v14, %v17
  br i1 %v15, label %b5, label %b6

b5:
  %v20 = add i64 0, 2
  %v18 = mul i64 %v13, %v20
  %v23 = add i64 0, 1
  %v21 = add i64 %v14, %v23
  br label %b4

b6:
  %v26 = add i64 0, 1
  %v24 = sub i64 %v13, %v26
  %v29 = add i64 0, 42
  store i64 %v29, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v24, ptr %ts1.valp)
  call void @glm_tbl_get(ptr %v0, i64 %v24, ptr %ts2.dst)
  %v30 = load i64, ptr %ts2.dst
  call void @glm_print_int(i64 %v30)
  call void @glm_print_nl()
  %v33 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_int(i64 %v33)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
