@.str.0 = private unnamed_addr constant [53 x i8] c"If you see this, the bullet missed the vital organs.\00"
declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_reserve(ptr, i64)
declare void @glm_tbl_free(ptr)
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
  %ts4.valp = alloca i64
  %ts5.valp = alloca i64
  %ts6.dst = alloca i64
  %ts8.valp = alloca i64
  %ts9.valp = alloca i64
  %ts10.valp = alloca i64
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
  call void @glm_tbl_free(ptr %v0)
  %v35 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v36 = add i64 0, 0
  %v37 = add i64 0, 1000
  call void @glm_tbl_reserve(ptr %v35, i64 %v37)
  br label %b7

b7:
  %v38 = phi i64 [ %v36, %b6 ], [ %v43, %bts4cont ]
  %v39 = icmp slt i64 %v38, %v37
  br i1 %v39, label %b8, label %b9

b8:
%ts4.d = load ptr, ptr %v35, !alias.scope !0
%ts4.s = getelementptr inbounds i64, ptr %ts4.d, i64 %v38
store i64 %v38, ptr %ts4.s, !noalias !0
br label %bts4cont

bts4cont:
  %v45 = add i64 0, 1
  %v43 = add i64 %v38, %v45
  br label %b7

b9:
  %v46 = add i64 0, 1
  %v47 = add i64 0, 0
  br label %b10

b10:
  %v48 = phi i64 [ %v46, %b9 ], [ %v53, %b11 ]
  %v49 = phi i64 [ %v47, %b9 ], [ %v56, %b11 ]
  %v52 = add i64 0, 63
  %v50 = icmp slt i64 %v49, %v52
  br i1 %v50, label %b11, label %b12

b11:
  %v55 = add i64 0, 2
  %v53 = mul i64 %v48, %v55
  %v58 = add i64 0, 1
  %v56 = add i64 %v49, %v58
  br label %b10

b12:
  %v61 = add i64 0, 1
  %v59 = sub i64 %v48, %v61
  %v64 = add i64 0, 40
  store i64 %v64, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v35, i64 %v59, ptr %ts5.valp)
  call void @glm_tbl_get(ptr %v35, i64 %v59, ptr %ts6.dst)
  %v65 = load i64, ptr %ts6.dst
  call void @glm_print_int(i64 %v65)
  call void @glm_print_nl()
  %v68 = call i64 @glm_tbl_len(ptr %v35)
  call void @glm_print_int(i64 %v68)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v35)
  %v70 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v72 = add i64 0, 0
  %v73 = add i64 0, 1
  store i64 %v73, ptr %ts8.valp
  call void @glm_tbl_set(ptr %v70, i64 %v72, ptr %ts8.valp)
  %v74 = add i64 0, 1
  %v75 = add i64 0, 0
  br label %b13

b13:
  %v76 = phi i64 [ %v74, %b12 ], [ %v81, %b14 ]
  %v77 = phi i64 [ %v75, %b12 ], [ %v84, %b14 ]
  %v80 = add i64 0, 63
  %v78 = icmp slt i64 %v77, %v80
  br i1 %v78, label %b14, label %b15

b14:
  %v83 = add i64 0, 2
  %v81 = mul i64 %v76, %v83
  %v86 = add i64 0, 1
  %v84 = add i64 %v77, %v86
  br label %b13

b15:
  %v89 = add i64 0, 1
  %v87 = sub i64 %v76, %v89
  %v92 = add i64 0, 1099511627776
  store i64 %v92, ptr %ts9.valp
  call void @glm_tbl_set(ptr %v70, i64 %v87, ptr %ts9.valp)
  %v94 = add i64 0, 10
  %v95 = add i64 0, 42
  store i64 %v95, ptr %ts10.valp
  call void @glm_tbl_set(ptr %v70, i64 %v94, ptr %ts10.valp)
  %v96 = getelementptr inbounds [53 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v96)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v70)
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
