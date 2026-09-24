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
  %ts1.valp = alloca i64
  %ts2.dst = alloca i64
  %ts3.valp = alloca i64
  %ts5.dst = alloca i64
  %ts6.dst = alloca i64
  %ts7.valp = alloca i64
  %ts9.dst = alloca i64
  %ts10.dst = alloca i64
  %ts11.valp = alloca i64
  %ts13.dst = alloca i64
  %ts14.dst = alloca i64
  %ts15.valp = alloca i64
  %ts16.dst = alloca i64
  %ts17.valp = alloca i64
  %ts18.dst = alloca i64
  %ts20.valp = alloca i64
  %ts21.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v1 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_int(i64 %v1)
  call void @glm_print_nl()
  %v4 = add i64 0, 0
  %v5 = add i64 0, 41
  store i64 %v5, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  %v7 = add i64 0, 1
  %v11 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v11, ptr %ts2.dst)
  %v9 = load i64, ptr %ts2.dst
  %v12 = add i64 0, 1
  %v8 = add i64 %v9, %v12
  store i64 %v8, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v0, i64 %v7, ptr %ts3.valp)
  %v13 = call i64 @glm_tbl_len(ptr %v0)
  %v17 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v17, ptr %ts5.dst)
  %v15 = load i64, ptr %ts5.dst
  %v20 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v20, ptr %ts6.dst)
  %v18 = load i64, ptr %ts6.dst
  call void @glm_print_int(i64 %v13)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v15)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v18)
  call void @glm_print_nl()
  %v22 = add i64 0, 10
  %v23 = add i64 0, 7
  store i64 %v23, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v0, i64 %v22, ptr %ts7.valp)
  %v24 = call i64 @glm_tbl_len(ptr %v0)
  %v28 = add i64 0, 5
  call void @glm_tbl_get(ptr %v0, i64 %v28, ptr %ts9.dst)
  %v26 = load i64, ptr %ts9.dst
  %v31 = add i64 0, 10
  call void @glm_tbl_get(ptr %v0, i64 %v31, ptr %ts10.dst)
  %v29 = load i64, ptr %ts10.dst
  call void @glm_print_int(i64 %v24)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v26)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v29)
  call void @glm_print_nl()
  %v32 = getelementptr i8, ptr %v0, i64 0
  %v34 = add i64 0, 20
  %v35 = add i64 0, 99
  store i64 %v35, ptr %ts11.valp
  call void @glm_tbl_set(ptr %v32, i64 %v34, ptr %ts11.valp)
  %v36 = call i64 @glm_tbl_len(ptr %v0)
  %v40 = add i64 0, 20
  call void @glm_tbl_get(ptr %v0, i64 %v40, ptr %ts13.dst)
  %v38 = load i64, ptr %ts13.dst
  %v43 = add i64 0, 0
  call void @glm_tbl_get(ptr %v32, i64 %v43, ptr %ts14.dst)
  %v41 = load i64, ptr %ts14.dst
  call void @glm_print_int(i64 %v36)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v38)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v41)
  call void @glm_print_nl()
  %v44 = add i64 0, 100
  %v45 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v0, i64 %v44)
  br label %b1

b1:
  %v47 = phi i64 [ %v45, %b0 ], [ %v54, %bts15cont ]
  %v48 = icmp slt i64 %v47, %v44
  br i1 %v48, label %b2, label %b3

b2:
  %v53 = add i64 0, 2
  %v51 = mul i64 %v47, %v53
%ts15.d = load ptr, ptr %v0, !alias.scope !0
%ts15.s = getelementptr inbounds i64, ptr %ts15.d, i64 %v47
store i64 %v51, ptr %ts15.s, !noalias !0
br label %bts15cont

bts15cont:
  %v56 = add i64 0, 1
  %v54 = add i64 %v47, %v56
  br label %b1

b3:
  %v57 = add i64 0, 0
  %v58 = add i64 0, 0
  br label %b4

b4:
  %v59 = phi i64 [ %v57, %b3 ], [ %v64, %b5 ]
  %v60 = phi i64 [ %v58, %b3 ], [ %v69, %b5 ]
  %v61 = icmp slt i64 %v60, %v44
  br i1 %v61, label %b5, label %b6

b5:
  call void @glm_tbl_get(ptr %v0, i64 %v60, ptr %ts16.dst)
  %v66 = load i64, ptr %ts16.dst
  %v64 = add i64 %v59, %v66
  %v71 = add i64 0, 1
  %v69 = add i64 %v60, %v71
  br label %b4

b6:
  call void @glm_print_int(i64 %v59)
  call void @glm_print_nl()
  %v73 = inttoptr i64 0 to ptr
  %v74 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v76 = add i64 0, 0
  %v77 = add i64 0, 5
  store i64 %v77, ptr %ts17.valp
  call void @glm_tbl_set(ptr %v74, i64 %v76, ptr %ts17.valp)
  %v80 = add i64 0, 0
  call void @glm_tbl_get(ptr %v74, i64 %v80, ptr %ts18.dst)
  %v78 = load i64, ptr %ts18.dst
  %v81 = call i64 @glm_tbl_len(ptr %v74)
  call void @glm_print_int(i64 %v78)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v81)
  call void @glm_print_nl()
  %v83 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v85 = add i64 0, 1
  %v86 = add i64 0, 2
  %v84 = icmp slt i64 %v86, %v85
  br i1 %v84, label %b7, label %b8

b7:
  %v87 = call ptr @glm_tbl_new(i64 8, i8 0)
  br label %b9

b8:
  %v88 = getelementptr i8, ptr %v74, i64 0
  br label %b9

b9:
  %v89 = phi ptr [ %v87, %b7 ], [ %v88, %b8 ]
  %v91 = add i64 0, 1
  %v92 = add i64 0, 3
  store i64 %v92, ptr %ts20.valp
  call void @glm_tbl_set(ptr %v89, i64 %v91, ptr %ts20.valp)
  %v95 = add i64 0, 1
  call void @glm_tbl_get(ptr %v74, i64 %v95, ptr %ts21.dst)
  %v93 = load i64, ptr %ts21.dst
  %v96 = call i64 @glm_tbl_len(ptr %v74)
  call void @glm_print_int(i64 %v93)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v96)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
