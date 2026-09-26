@.str.0 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"world\00"
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
  %ts0.valp = alloca i64
  %ts1.valp = alloca i64
  %ts2.valp = alloca i64
  %ts3.dst = alloca i64
  %ts4.dst = alloca i64
  %ts5.dst = alloca i64
  %ts7.valp = alloca double
  %ts8.valp = alloca double
  %ts9.dst = alloca double
  %ts10.dst = alloca double
  %ts11.dst = alloca double
  %ts12.valp = alloca ptr
  %ts13.valp = alloca ptr
  %ts14.dst = alloca ptr
  %ts15.dst = alloca ptr
  %ts16.valp = alloca i8
  %ts17.valp = alloca i8
  %ts18.dst = alloca i8
  %ts19.dst = alloca i8
  %ts20.dst = alloca i8
  %ts21.valp = alloca i64
  %ts22.dst = alloca i64
  %ts23.valp = alloca i64
  %ts24.valp = alloca i64
  %ts25.dst = alloca i64
  %ts26.dst = alloca i64
  br label %b0

b0:
  %v1 = add i64 0, 10
  %v2 = add i64 0, 20
  %v3 = add i64 0, 30
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v4 = add i64 0, 0
  store i64 %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts0.valp)
  %v5 = add i64 0, 1
  store i64 %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v5, ptr %ts1.valp)
  %v6 = add i64 0, 2
  store i64 %v3, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v0, i64 %v6, ptr %ts2.valp)
  %v9 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v9, ptr %ts3.dst)
  %v7 = load i64, ptr %ts3.dst
  %v12 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v12, ptr %ts4.dst)
  %v10 = load i64, ptr %ts4.dst
  %v15 = add i64 0, 2
  call void @glm_tbl_get(ptr %v0, i64 %v15, ptr %ts5.dst)
  %v13 = load i64, ptr %ts5.dst
  %v16 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_int(i64 %v7)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v10)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v13)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v16)
  call void @glm_print_nl()
  %v19 = fadd double 0.0, 1.5
  %v20 = fadd double 0.0, 2.5
  %v18 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v21 = add i64 0, 0
  store double %v19, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v18, i64 %v21, ptr %ts7.valp)
  %v22 = add i64 0, 1
  store double %v20, ptr %ts8.valp
  call void @glm_tbl_set(ptr %v18, i64 %v22, ptr %ts8.valp)
  %v25 = add i64 0, 0
  call void @glm_tbl_get(ptr %v18, i64 %v25, ptr %ts9.dst)
  %v23 = load double, ptr %ts9.dst
  %v28 = add i64 0, 1
  call void @glm_tbl_get(ptr %v18, i64 %v28, ptr %ts10.dst)
  %v26 = load double, ptr %ts10.dst
  %v31 = add i64 0, 2
  call void @glm_tbl_get(ptr %v18, i64 %v31, ptr %ts11.dst)
  %v29 = load double, ptr %ts11.dst
  call void @glm_print_float(double %v23)
  call void @glm_print_sep()
  call void @glm_print_float(double %v26)
  call void @glm_print_sep()
  call void @glm_print_float(double %v29)
  call void @glm_print_nl()
  %v33 = getelementptr inbounds [6 x i8], ptr @.str.0, i64 0, i64 0
  %v34 = getelementptr inbounds [6 x i8], ptr @.str.1, i64 0, i64 0
  %v32 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v35 = add i64 0, 0
  store ptr %v33, ptr %ts12.valp
  call void @glm_tbl_set(ptr %v32, i64 %v35, ptr %ts12.valp)
  %v36 = add i64 0, 1
  store ptr %v34, ptr %ts13.valp
  call void @glm_tbl_set(ptr %v32, i64 %v36, ptr %ts13.valp)
  %v39 = add i64 0, 0
  call void @glm_tbl_get(ptr %v32, i64 %v39, ptr %ts14.dst)
  %v37 = load ptr, ptr %ts14.dst
  %v42 = add i64 0, 1
  call void @glm_tbl_get(ptr %v32, i64 %v42, ptr %ts15.dst)
  %v40 = load ptr, ptr %ts15.dst
  call void @glm_print_string(ptr %v37)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v40)
  call void @glm_print_nl()
  %v44 = or i1 0, 1
  %v45 = or i1 0, 0
  %v43 = call ptr @glm_tbl_new(i64 1, i8 0)
  %v46 = add i64 0, 0
  %ts16.z = zext i1 %v44 to i8
store i8 %ts16.z, ptr %ts16.valp
  call void @glm_tbl_set(ptr %v43, i64 %v46, ptr %ts16.valp)
  %v47 = add i64 0, 1
  %ts17.z = zext i1 %v45 to i8
store i8 %ts17.z, ptr %ts17.valp
  call void @glm_tbl_set(ptr %v43, i64 %v47, ptr %ts17.valp)
  %v50 = add i64 0, 0
  call void @glm_tbl_get(ptr %v43, i64 %v50, ptr %ts18.dst)
  %ts18.c = load i8, ptr %ts18.dst
%v48 = icmp ne i8 %ts18.c, 0
  %v53 = add i64 0, 1
  call void @glm_tbl_get(ptr %v43, i64 %v53, ptr %ts19.dst)
  %ts19.c = load i8, ptr %ts19.dst
%v51 = icmp ne i8 %ts19.c, 0
  %v56 = add i64 0, 2
  call void @glm_tbl_get(ptr %v43, i64 %v56, ptr %ts20.dst)
  %ts20.c = load i8, ptr %ts20.dst
%v54 = icmp ne i8 %ts20.c, 0
  call void @glm_print_bool(i1 %v48)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v51)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v54)
  call void @glm_print_nl()
  %v57 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v59 = add i64 0, 0
  %v60 = add i64 0, 9
  store i64 %v60, ptr %ts21.valp
  call void @glm_tbl_set(ptr %v57, i64 %v59, ptr %ts21.valp)
  %v63 = add i64 0, 0
  call void @glm_tbl_get(ptr %v57, i64 %v63, ptr %ts22.dst)
  %v61 = load i64, ptr %ts22.dst
  call void @glm_print_int(i64 %v61)
  call void @glm_print_nl()
  %v65 = add i64 0, 1
  %v66 = add i64 0, 2
  %v64 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v67 = add i64 0, 0
  store i64 %v65, ptr %ts23.valp
  call void @glm_tbl_set(ptr %v64, i64 %v67, ptr %ts23.valp)
  %v68 = add i64 0, 1
  store i64 %v66, ptr %ts24.valp
  call void @glm_tbl_set(ptr %v64, i64 %v68, ptr %ts24.valp)
  %v71 = add i64 0, 0
  call void @glm_tbl_get(ptr %v64, i64 %v71, ptr %ts25.dst)
  %v69 = load i64, ptr %ts25.dst
  %v74 = add i64 0, 1
  call void @glm_tbl_get(ptr %v64, i64 %v74, ptr %ts26.dst)
  %v72 = load i64, ptr %ts26.dst
  call void @glm_print_int(i64 %v69)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v72)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v64)
  call void @glm_tbl_free(ptr %v57)
  call void @glm_tbl_free(ptr %v43)
  call void @glm_tbl_free(ptr %v32)
  call void @glm_tbl_free(ptr %v18)
  call void @glm_tbl_free(ptr %v0)
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
