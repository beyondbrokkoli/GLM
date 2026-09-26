@.str.0 = private unnamed_addr constant [20 x i8] c"survived double nil\00"
@.str.1 = private unnamed_addr constant [13 x i8] c"loop drop ok\00"
@.str.2 = private unnamed_addr constant [7 x i8] c"leaked\00"
@.str.3 = private unnamed_addr constant [7 x i8] c"leaked\00"
declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_free(ptr)
declare void @glm_tbl_get(ptr, i64, ptr)
declare void @glm_tbl_set(ptr, i64, ptr)
declare i64 @glm_tbl_len(ptr)
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
  %ts3.dst = alloca i64
  %ts4.valp = alloca i64
  %ts5.dst = alloca i64
  %ts7.valp = alloca i64
  %ts8.valp = alloca i64
  %ts9.valp = alloca i64
  %ts10.dst = alloca i64
  %ts11.valp = alloca i64
  %ts12.dst = alloca i64
  %ts13.dst = alloca i64
  %ts14.valp = alloca i64
  %ts15.valp = alloca i64
  %ts16.valp = alloca i64
  %ts17.valp = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = add i64 0, 41
  store i64 %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  call void @glm_tbl_free(ptr %v0)
  %v4 = inttoptr i64 0 to ptr
  %v5 = inttoptr i64 0 to ptr
  %v6 = getelementptr inbounds [20 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v6)
  call void @glm_print_nl()
  %v7 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v9 = add i64 0, 0
  %v10 = add i64 0, 41
  store i64 %v10, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v7, i64 %v9, ptr %ts1.valp)
  %v11 = add i64 0, 0
  br label %b1

b1:
  %v12 = phi ptr [ %v7, %b0 ], [ %v17, %b2 ]
  %v13 = phi i64 [ %v11, %b0 ], [ %v18, %b2 ]
  %v16 = add i64 0, 3
  %v14 = icmp slt i64 %v13, %v16
  br i1 %v14, label %b2, label %b3

b2:
  call void @glm_tbl_free(ptr %v12)
  %v17 = inttoptr i64 0 to ptr
  %v20 = add i64 0, 1
  %v18 = add i64 %v13, %v20
  br label %b1

b3:
  %v21 = getelementptr inbounds [13 x i8], ptr @.str.1, i64 0, i64 0
  call void @glm_print_string(ptr %v21)
  call void @glm_print_nl()
  %v22 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v24 = add i64 0, 0
  %v25 = add i64 0, 7
  store i64 %v25, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v22, i64 %v24, ptr %ts2.valp)
  %v26 = getelementptr i8, ptr %v22, i64 0
  %v27 = inttoptr i64 0 to ptr
  %v30 = add i64 0, 0
  call void @glm_tbl_get(ptr %v26, i64 %v30, ptr %ts3.dst)
  %v28 = load i64, ptr %ts3.dst
  call void @glm_print_int(i64 %v28)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v26)
  %v31 = inttoptr i64 0 to ptr
  %v32 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v34 = add i64 0, 1
  %v35 = add i64 0, 9
  store i64 %v35, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v32, i64 %v34, ptr %ts4.valp)
  %v38 = add i64 0, 1
  call void @glm_tbl_get(ptr %v32, i64 %v38, ptr %ts5.dst)
  %v36 = load i64, ptr %ts5.dst
  %v39 = call i64 @glm_tbl_len(ptr %v32)
  call void @glm_print_int(i64 %v36)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v39)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v32)
  %v41 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v43 = add i64 0, 0
  %v44 = add i64 0, 1
  store i64 %v44, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v41, i64 %v43, ptr %ts7.valp)
  %v45 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v47 = add i64 0, 0
  %v48 = add i64 0, 2
  store i64 %v48, ptr %ts8.valp
  call void @glm_tbl_set(ptr %v45, i64 %v47, ptr %ts8.valp)
  %v49 = getelementptr i8, ptr %v41, i64 0
  %v51 = add i64 0, 1
  %v52 = add i64 0, 2
  %v50 = icmp slt i64 %v52, %v51
  br i1 %v50, label %b4, label %b5

b4:
  %v53 = getelementptr i8, ptr %v45, i64 0
  br label %b6

b5:
  br label %b6

b6:
  %v54 = phi ptr [ %v53, %b4 ], [ %v49, %b5 ]
  %v56 = add i64 0, 0
  %v57 = add i64 0, 5
  store i64 %v57, ptr %ts9.valp
  call void @glm_tbl_set(ptr %v54, i64 %v56, ptr %ts9.valp)
  %v58 = inttoptr i64 0 to ptr
  %v60 = add i64 0, 0
  %v64 = add i64 0, 0
  call void @glm_tbl_get(ptr %v41, i64 %v64, ptr %ts10.dst)
  %v62 = load i64, ptr %ts10.dst
  %v65 = add i64 0, 1
  %v61 = add i64 %v62, %v65
  store i64 %v61, ptr %ts11.valp
  call void @glm_tbl_set(ptr %v41, i64 %v60, ptr %ts11.valp)
  %v68 = add i64 0, 0
  call void @glm_tbl_get(ptr %v41, i64 %v68, ptr %ts12.dst)
  %v66 = load i64, ptr %ts12.dst
  %v71 = add i64 0, 0
  call void @glm_tbl_get(ptr %v45, i64 %v71, ptr %ts13.dst)
  %v69 = load i64, ptr %ts13.dst
  call void @glm_print_int(i64 %v66)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v69)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v45)
  call void @glm_tbl_free(ptr %v41)
  %v72 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v74 = add i64 0, 0
  %v75 = add i64 0, 1
  store i64 %v75, ptr %ts14.valp
  call void @glm_tbl_set(ptr %v72, i64 %v74, ptr %ts14.valp)
  %v76 = inttoptr i64 0 to ptr
  %v77 = getelementptr i8, ptr %v72, i64 0
  %v78 = inttoptr i64 0 to ptr
  %v80 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v80)
  call void @glm_print_nl()
  %v81 = getelementptr inbounds [7 x i8], ptr @.str.2, i64 0, i64 0
  call void @glm_print_string(ptr %v81)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v72)
  %v82 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v84 = add i64 0, 0
  %v85 = add i64 0, 1
  store i64 %v85, ptr %ts15.valp
  call void @glm_tbl_set(ptr %v82, i64 %v84, ptr %ts15.valp)
  %v86 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v88 = add i64 0, 0
  %v89 = add i64 0, 2
  store i64 %v89, ptr %ts16.valp
  call void @glm_tbl_set(ptr %v86, i64 %v88, ptr %ts16.valp)
  %v90 = getelementptr i8, ptr %v82, i64 0
  %v91 = or i1 0, 0
  br i1 %v91, label %b7, label %b8

b7:
  %v92 = getelementptr i8, ptr %v86, i64 0
  br label %b9

b8:
  br label %b9

b9:
  %v93 = phi ptr [ %v92, %b7 ], [ %v90, %b8 ]
  %v95 = add i64 0, 0
  %v96 = add i64 0, 5
  store i64 %v96, ptr %ts17.valp
  call void @glm_tbl_set(ptr %v93, i64 %v95, ptr %ts17.valp)
  %v97 = inttoptr i64 0 to ptr
  %v99 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v99)
  call void @glm_print_nl()
  %v100 = getelementptr inbounds [7 x i8], ptr @.str.3, i64 0, i64 0
  call void @glm_print_string(ptr %v100)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v86)
  call void @glm_tbl_free(ptr %v82)
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
