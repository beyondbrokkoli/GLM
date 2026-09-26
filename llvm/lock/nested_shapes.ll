declare ptr @glm_tbl_new(i64, i8)
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
  %ts0.valp = alloca ptr
  %ts1.dst = alloca ptr
  %ts2.dst = alloca i64
  %ts3.valp = alloca ptr
  %ts4.dst = alloca ptr
  %ts5.dst = alloca i64
  %ts6.valp = alloca i64
  %ts7.valp = alloca i64
  %ts8.valp = alloca i64
  %ts9.valp = alloca i64
  %ts10.valp = alloca ptr
  %ts11.valp = alloca ptr
  %ts12.dst = alloca ptr
  %ts13.dst = alloca i64
  %ts14.dst = alloca ptr
  %ts15.dst = alloca i64
  %ts16.dst = alloca ptr
  %ts17.dst = alloca i64
  %ts18.dst = alloca ptr
  %ts19.dst = alloca i64
  %ts20.valp = alloca i64
  %ts21.valp = alloca i64
  %ts22.valp = alloca i64
  %ts23.valp = alloca i64
  %ts24.valp = alloca ptr
  %ts25.valp = alloca ptr
  %ts26.dst = alloca ptr
  %ts27.valp = alloca i64
  %ts28.dst = alloca ptr
  %ts29.dst = alloca i64
  %ts30.dst = alloca ptr
  %ts31.dst = alloca i64
  %ts32.dst = alloca ptr
  %ts33.dst = alloca i64
  %ts34.dst = alloca ptr
  %ts35.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = call ptr @glm_tbl_new(i64 8, i8 0)
  store ptr %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v7 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v7, ptr %ts1.dst)
  %ts1.loaded = load i64, ptr %ts1.dst
%v5 = inttoptr i64 %ts1.loaded to ptr
  %v8 = add i64 0, 0
  call void @glm_tbl_get(ptr %v5, i64 %v8, ptr %ts2.dst)
  %v4 = load i64, ptr %ts2.dst
  call void @glm_print_int(i64 %v4)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v0)
  %v9 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v10 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v12 = add i64 0, 0
  store ptr %v9, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v10, i64 %v12, ptr %ts3.valp)
  %v17 = add i64 0, 0
  call void @glm_tbl_get(ptr %v10, i64 %v17, ptr %ts4.dst)
  %ts4.loaded = load i64, ptr %ts4.dst
%v15 = inttoptr i64 %ts4.loaded to ptr
  %v18 = add i64 0, 0
  call void @glm_tbl_get(ptr %v15, i64 %v18, ptr %ts5.dst)
  %v14 = load i64, ptr %ts5.dst
  call void @glm_print_int(i64 %v14)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v10)
  call void @glm_tbl_free(ptr %v9)
  %v19 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v21 = add i64 0, 0
  %v22 = add i64 0, 1
  store i64 %v22, ptr %ts6.valp
  call void @glm_tbl_set(ptr %v19, i64 %v21, ptr %ts6.valp)
  %v24 = add i64 0, 1
  %v25 = add i64 0, 2
  store i64 %v25, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v19, i64 %v24, ptr %ts7.valp)
  %v26 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v28 = add i64 0, 0
  %v29 = add i64 0, 3
  store i64 %v29, ptr %ts8.valp
  call void @glm_tbl_set(ptr %v26, i64 %v28, ptr %ts8.valp)
  %v31 = add i64 0, 1
  %v32 = add i64 0, 4
  store i64 %v32, ptr %ts9.valp
  call void @glm_tbl_set(ptr %v26, i64 %v31, ptr %ts9.valp)
  %v33 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v35 = add i64 0, 0
  store ptr %v19, ptr %ts10.valp
  call void @glm_tbl_set(ptr %v33, i64 %v35, ptr %ts10.valp)
  %v38 = add i64 0, 1
  store ptr %v26, ptr %ts11.valp
  call void @glm_tbl_set(ptr %v33, i64 %v38, ptr %ts11.valp)
  %v43 = add i64 0, 0
  call void @glm_tbl_get(ptr %v33, i64 %v43, ptr %ts12.dst)
  %ts12.loaded = load i64, ptr %ts12.dst
%v41 = inttoptr i64 %ts12.loaded to ptr
  %v44 = add i64 0, 0
  call void @glm_tbl_get(ptr %v41, i64 %v44, ptr %ts13.dst)
  %v40 = load i64, ptr %ts13.dst
  call void @glm_print_int(i64 %v40)
  call void @glm_print_nl()
  %v48 = add i64 0, 0
  call void @glm_tbl_get(ptr %v33, i64 %v48, ptr %ts14.dst)
  %ts14.loaded = load i64, ptr %ts14.dst
%v46 = inttoptr i64 %ts14.loaded to ptr
  %v49 = add i64 0, 1
  call void @glm_tbl_get(ptr %v46, i64 %v49, ptr %ts15.dst)
  %v45 = load i64, ptr %ts15.dst
  call void @glm_print_int(i64 %v45)
  call void @glm_print_nl()
  %v53 = add i64 0, 1
  call void @glm_tbl_get(ptr %v33, i64 %v53, ptr %ts16.dst)
  %ts16.loaded = load i64, ptr %ts16.dst
%v51 = inttoptr i64 %ts16.loaded to ptr
  %v54 = add i64 0, 0
  call void @glm_tbl_get(ptr %v51, i64 %v54, ptr %ts17.dst)
  %v50 = load i64, ptr %ts17.dst
  call void @glm_print_int(i64 %v50)
  call void @glm_print_nl()
  %v58 = add i64 0, 1
  call void @glm_tbl_get(ptr %v33, i64 %v58, ptr %ts18.dst)
  %ts18.loaded = load i64, ptr %ts18.dst
%v56 = inttoptr i64 %ts18.loaded to ptr
  %v59 = add i64 0, 1
  call void @glm_tbl_get(ptr %v56, i64 %v59, ptr %ts19.dst)
  %v55 = load i64, ptr %ts19.dst
  call void @glm_print_int(i64 %v55)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v33)
  call void @glm_tbl_free(ptr %v26)
  call void @glm_tbl_free(ptr %v19)
  %v60 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v62 = add i64 0, 0
  %v63 = add i64 0, 1
  store i64 %v63, ptr %ts20.valp
  call void @glm_tbl_set(ptr %v60, i64 %v62, ptr %ts20.valp)
  %v65 = add i64 0, 1
  %v66 = add i64 0, 2
  store i64 %v66, ptr %ts21.valp
  call void @glm_tbl_set(ptr %v60, i64 %v65, ptr %ts21.valp)
  %v67 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v69 = add i64 0, 0
  %v70 = add i64 0, 3
  store i64 %v70, ptr %ts22.valp
  call void @glm_tbl_set(ptr %v67, i64 %v69, ptr %ts22.valp)
  %v72 = add i64 0, 1
  %v73 = add i64 0, 4
  store i64 %v73, ptr %ts23.valp
  call void @glm_tbl_set(ptr %v67, i64 %v72, ptr %ts23.valp)
  %v74 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v76 = add i64 0, 0
  store ptr %v60, ptr %ts24.valp
  call void @glm_tbl_set(ptr %v74, i64 %v76, ptr %ts24.valp)
  %v79 = add i64 0, 1
  store ptr %v67, ptr %ts25.valp
  call void @glm_tbl_set(ptr %v74, i64 %v79, ptr %ts25.valp)
  %v83 = add i64 0, 0
  call void @glm_tbl_get(ptr %v74, i64 %v83, ptr %ts26.dst)
  %ts26.loaded = load i64, ptr %ts26.dst
%v81 = inttoptr i64 %ts26.loaded to ptr
  %v84 = add i64 0, 0
  %v85 = add i64 0, 42
  store i64 %v85, ptr %ts27.valp
  call void @glm_tbl_set(ptr %v81, i64 %v84, ptr %ts27.valp)
  %v89 = add i64 0, 0
  call void @glm_tbl_get(ptr %v74, i64 %v89, ptr %ts28.dst)
  %ts28.loaded = load i64, ptr %ts28.dst
%v87 = inttoptr i64 %ts28.loaded to ptr
  %v90 = add i64 0, 0
  call void @glm_tbl_get(ptr %v87, i64 %v90, ptr %ts29.dst)
  %v86 = load i64, ptr %ts29.dst
  call void @glm_print_int(i64 %v86)
  call void @glm_print_nl()
  %v94 = add i64 0, 0
  call void @glm_tbl_get(ptr %v74, i64 %v94, ptr %ts30.dst)
  %ts30.loaded = load i64, ptr %ts30.dst
%v92 = inttoptr i64 %ts30.loaded to ptr
  %v95 = add i64 0, 1
  call void @glm_tbl_get(ptr %v92, i64 %v95, ptr %ts31.dst)
  %v91 = load i64, ptr %ts31.dst
  call void @glm_print_int(i64 %v91)
  call void @glm_print_nl()
  %v99 = add i64 0, 1
  call void @glm_tbl_get(ptr %v74, i64 %v99, ptr %ts32.dst)
  %ts32.loaded = load i64, ptr %ts32.dst
%v97 = inttoptr i64 %ts32.loaded to ptr
  %v100 = add i64 0, 0
  call void @glm_tbl_get(ptr %v97, i64 %v100, ptr %ts33.dst)
  %v96 = load i64, ptr %ts33.dst
  call void @glm_print_int(i64 %v96)
  call void @glm_print_nl()
  %v104 = add i64 0, 1
  call void @glm_tbl_get(ptr %v74, i64 %v104, ptr %ts34.dst)
  %ts34.loaded = load i64, ptr %ts34.dst
%v102 = inttoptr i64 %ts34.loaded to ptr
  %v105 = add i64 0, 1
  call void @glm_tbl_get(ptr %v102, i64 %v105, ptr %ts35.dst)
  %v101 = load i64, ptr %ts35.dst
  call void @glm_print_int(i64 %v101)
  call void @glm_print_nl()
  %v106 = call i64 @glm_tbl_len(ptr %v74)
  call void @glm_print_int(i64 %v106)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v74)
  call void @glm_tbl_free(ptr %v67)
  call void @glm_tbl_free(ptr %v60)
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
