@.str.0 = private unnamed_addr constant [7 x i8] c"string\00"
@.str.1 = private unnamed_addr constant [7 x i8] c"string\00"
declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_free(ptr)
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
  %ts3.valp = alloca i64
  %ts4.valp = alloca ptr
  %ts5.valp = alloca ptr
  %ts6.dst = alloca ptr
  %ts7.dst = alloca i64
  %ts8.dst = alloca ptr
  %ts9.dst = alloca i64
  %ts10.dst = alloca ptr
  %ts11.dst = alloca i64
  %ts12.dst = alloca ptr
  %ts13.dst = alloca i64
  %ts14.valp = alloca ptr
  %ts15.dst = alloca ptr
  %ts16.valp = alloca ptr
  %ts17.dst = alloca ptr
  %ts18.dst = alloca ptr
  %ts19.valp = alloca ptr
  %ts20.valp = alloca ptr
  %ts21.dst = alloca ptr
  %ts22.dst = alloca ptr
  %ts23.dst = alloca ptr
  %ts24.valp = alloca i64
  %ts25.dst = alloca ptr
  %ts26.dst = alloca i64
  %ts27.valp = alloca i64
  %ts28.valp = alloca i64
  %ts29.valp = alloca ptr
  %ts30.dst = alloca ptr
  %ts31.dst = alloca i64
  br label %b0

b0:
  %v2 = add i64 0, 1
  %v3 = add i64 0, 2
  %v1 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v4 = add i64 0, 0
  store i64 %v2, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v1, i64 %v4, ptr %ts0.valp)
  %v5 = add i64 0, 1
  store i64 %v3, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v1, i64 %v5, ptr %ts1.valp)
  %v7 = add i64 0, 3
  %v8 = add i64 0, 4
  %v6 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v9 = add i64 0, 0
  store i64 %v7, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v6, i64 %v9, ptr %ts2.valp)
  %v10 = add i64 0, 1
  store i64 %v8, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v6, i64 %v10, ptr %ts3.valp)
  %v0 = call ptr @glm_tbl_new(i64 8, i8 128)
  %v11 = add i64 0, 0
  store ptr %v1, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v0, i64 %v11, ptr %ts4.valp)
  %v12 = add i64 0, 1
  store ptr %v6, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v0, i64 %v12, ptr %ts5.valp)
  %v16 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v16, ptr %ts6.dst)
  %v14 = load ptr, ptr %ts6.dst
  %v17 = add i64 0, 0
  call void @glm_tbl_get(ptr %v14, i64 %v17, ptr %ts7.dst)
  %v13 = load i64, ptr %ts7.dst
  %v21 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v21, ptr %ts8.dst)
  %v19 = load ptr, ptr %ts8.dst
  %v22 = add i64 0, 1
  call void @glm_tbl_get(ptr %v19, i64 %v22, ptr %ts9.dst)
  %v18 = load i64, ptr %ts9.dst
  %v26 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v26, ptr %ts10.dst)
  %v24 = load ptr, ptr %ts10.dst
  %v27 = add i64 0, 0
  call void @glm_tbl_get(ptr %v24, i64 %v27, ptr %ts11.dst)
  %v23 = load i64, ptr %ts11.dst
  %v31 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v31, ptr %ts12.dst)
  %v29 = load ptr, ptr %ts12.dst
  %v32 = add i64 0, 1
  call void @glm_tbl_get(ptr %v29, i64 %v32, ptr %ts13.dst)
  %v28 = load i64, ptr %ts13.dst
  call void @glm_print_int(i64 %v13)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v18)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v23)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v28)
  call void @glm_print_nl()
  %v33 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v34 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v36 = add i64 0, 0
  store ptr %v33, ptr %ts14.valp
  call void @glm_tbl_set(ptr %v34, i64 %v36, ptr %ts14.valp)
  %v40 = add i64 0, 0
  call void @glm_tbl_get(ptr %v34, i64 %v40, ptr %ts15.dst)
  %v38 = load ptr, ptr %ts15.dst
  %v41 = add i64 0, 0
  %v42 = getelementptr inbounds [7 x i8], ptr @.str.0, i64 0, i64 0
  store ptr %v42, ptr %ts16.valp
  call void @glm_tbl_set(ptr %v38, i64 %v41, ptr %ts16.valp)
  %v46 = add i64 0, 0
  call void @glm_tbl_get(ptr %v34, i64 %v46, ptr %ts17.dst)
  %v44 = load ptr, ptr %ts17.dst
  %v47 = add i64 0, 0
  call void @glm_tbl_get(ptr %v44, i64 %v47, ptr %ts18.dst)
  %v43 = load ptr, ptr %ts18.dst
  call void @glm_print_string(ptr %v43)
  call void @glm_print_nl()
  %v50 = getelementptr inbounds [7 x i8], ptr @.str.1, i64 0, i64 0
  %v49 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v51 = add i64 0, 0
  store ptr %v50, ptr %ts19.valp
  call void @glm_tbl_set(ptr %v49, i64 %v51, ptr %ts19.valp)
  %v48 = call ptr @glm_tbl_new(i64 8, i8 128)
  %v52 = add i64 0, 0
  store ptr %v49, ptr %ts20.valp
  call void @glm_tbl_set(ptr %v48, i64 %v52, ptr %ts20.valp)
  %v56 = add i64 0, 0
  call void @glm_tbl_get(ptr %v48, i64 %v56, ptr %ts21.dst)
  %v54 = load ptr, ptr %ts21.dst
  %v57 = add i64 0, 0
  call void @glm_tbl_get(ptr %v54, i64 %v57, ptr %ts22.dst)
  %v53 = load ptr, ptr %ts22.dst
  call void @glm_print_string(ptr %v53)
  call void @glm_print_nl()
  %v60 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v60, ptr %ts23.dst)
  %v58 = load ptr, ptr %ts23.dst
  %v61 = add i64 0, 0
  %v62 = add i64 0, 9
  store i64 %v62, ptr %ts24.valp
  call void @glm_tbl_set(ptr %v58, i64 %v61, ptr %ts24.valp)
  %v67 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v67, ptr %ts25.dst)
  %v65 = load ptr, ptr %ts25.dst
  %v68 = add i64 0, 0
  call void @glm_tbl_get(ptr %v65, i64 %v68, ptr %ts26.dst)
  %v64 = load i64, ptr %ts26.dst
  %v69 = add i64 0, 9
  %v63 = sub i64 %v64, %v69
  call void @glm_print_int(i64 %v63)
  call void @glm_print_nl()
  %v70 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v72 = add i64 0, 5
  %v73 = add i64 0, 6
  %v71 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v74 = add i64 0, 0
  store i64 %v72, ptr %ts27.valp
  call void @glm_tbl_set(ptr %v71, i64 %v74, ptr %ts27.valp)
  %v75 = add i64 0, 1
  store i64 %v73, ptr %ts28.valp
  call void @glm_tbl_set(ptr %v71, i64 %v75, ptr %ts28.valp)
  %v77 = add i64 0, 0
  store ptr %v71, ptr %ts29.valp
  call void @glm_tbl_set(ptr %v70, i64 %v77, ptr %ts29.valp)
  %v82 = add i64 0, 0
  call void @glm_tbl_get(ptr %v70, i64 %v82, ptr %ts30.dst)
  %v80 = load ptr, ptr %ts30.dst
  %v83 = add i64 0, 0
  call void @glm_tbl_get(ptr %v80, i64 %v83, ptr %ts31.dst)
  %v79 = load i64, ptr %ts31.dst
  call void @glm_print_int(i64 %v79)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v71)
  call void @glm_tbl_free(ptr %v70)
  call void @glm_tbl_free(ptr %v48)
  call void @glm_tbl_free(ptr %v34)
  call void @glm_tbl_free(ptr %v33)
  call void @glm_tbl_free(ptr %v0)
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
