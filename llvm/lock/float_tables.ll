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
  %ts1.valp = alloca double
  %ts3.dst = alloca double
  %ts4.dst = alloca double
  %ts5.dst = alloca double
  %ts6.valp = alloca double
  %ts8.dst = alloca double
  %ts9.dst = alloca double
  %ts10.valp = alloca double
  %ts12.dst = alloca double
  %ts13.dst = alloca double
  %ts14.dst = alloca double
  %ts15.valp = alloca double
  %ts16.dst = alloca double
  %ts17.dst = alloca double
  %ts18.dst = alloca double
  %ts20.dst = alloca double
  br label %b0

b0:
  %v1 = fadd double 0.0, 1.5
  %v2 = fadd double 0.0, 2.5
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  store double %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v3, ptr %ts0.valp)
  %v4 = add i64 0, 1
  store double %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  %v5 = call i64 @glm_tbl_len(ptr %v0)
  %v9 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v9, ptr %ts3.dst)
  %v7 = load double, ptr %ts3.dst
  %v12 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v12, ptr %ts4.dst)
  %v10 = load double, ptr %ts4.dst
  %v15 = add i64 0, 2
  call void @glm_tbl_get(ptr %v0, i64 %v15, ptr %ts5.dst)
  %v13 = load double, ptr %ts5.dst
  call void @glm_print_int(i64 %v5)
  call void @glm_print_sep()
  call void @glm_print_float(double %v7)
  call void @glm_print_sep()
  call void @glm_print_float(double %v10)
  call void @glm_print_sep()
  call void @glm_print_float(double %v13)
  call void @glm_print_nl()
  %v17 = add i64 0, 10
  %v18 = fadd double 0.0, 7.25
  store double %v18, ptr %ts6.valp
  call void @glm_tbl_set(ptr %v0, i64 %v17, ptr %ts6.valp)
  %v19 = call i64 @glm_tbl_len(ptr %v0)
  %v23 = add i64 0, 5
  call void @glm_tbl_get(ptr %v0, i64 %v23, ptr %ts8.dst)
  %v21 = load double, ptr %ts8.dst
  %v26 = add i64 0, 10
  call void @glm_tbl_get(ptr %v0, i64 %v26, ptr %ts9.dst)
  %v24 = load double, ptr %ts9.dst
  call void @glm_print_int(i64 %v19)
  call void @glm_print_sep()
  call void @glm_print_float(double %v21)
  call void @glm_print_sep()
  call void @glm_print_float(double %v24)
  call void @glm_print_nl()
  %v27 = getelementptr i8, ptr %v0, i64 0
  %v29 = add i64 0, 20
  %v30 = fadd double 0.0, 1.125
  store double %v30, ptr %ts10.valp
  call void @glm_tbl_set(ptr %v27, i64 %v29, ptr %ts10.valp)
  %v31 = call i64 @glm_tbl_len(ptr %v0)
  %v35 = add i64 0, 20
  call void @glm_tbl_get(ptr %v0, i64 %v35, ptr %ts12.dst)
  %v33 = load double, ptr %ts12.dst
  %v38 = add i64 0, 1
  call void @glm_tbl_get(ptr %v27, i64 %v38, ptr %ts13.dst)
  %v36 = load double, ptr %ts13.dst
  call void @glm_print_int(i64 %v31)
  call void @glm_print_sep()
  call void @glm_print_float(double %v33)
  call void @glm_print_sep()
  call void @glm_print_float(double %v36)
  call void @glm_print_nl()
  %v39 = add i64 0, 0
  %v40 = add i64 0, 24
  call void @glm_tbl_reserve(ptr %v0, i64 %v40)
  br label %b1

b1:
  %v41 = phi i64 [ %v39, %b0 ], [ %v52, %bts15cont ]
  %v42 = icmp slt i64 %v41, %v40
  br i1 %v42, label %b2, label %b3

b2:
  call void @glm_tbl_get(ptr %v0, i64 %v41, ptr %ts14.dst)
  %v47 = load double, ptr %ts14.dst
  %v50 = fadd double 0.0, 2.0
  %v46 = fmul double %v47, %v50
  %v51 = fadd double 0.0, 0.5
  %v45 = fadd double %v46, %v51
%ts15.d = load ptr, ptr %v0, !alias.scope !0
%ts15.s = getelementptr inbounds double, ptr %ts15.d, i64 %v41
store double %v45, ptr %ts15.s, !noalias !0
br label %bts15cont

bts15cont:
  %v54 = add i64 0, 1
  %v52 = add i64 %v41, %v54
  br label %b1

b3:
  %v57 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v57, ptr %ts16.dst)
  %v55 = load double, ptr %ts16.dst
  %v60 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v60, ptr %ts17.dst)
  %v58 = load double, ptr %ts17.dst
  %v63 = add i64 0, 23
  call void @glm_tbl_get(ptr %v0, i64 %v63, ptr %ts18.dst)
  %v61 = load double, ptr %ts18.dst
  %v64 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_float(double %v55)
  call void @glm_print_sep()
  call void @glm_print_float(double %v58)
  call void @glm_print_sep()
  call void @glm_print_float(double %v61)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v64)
  call void @glm_print_nl()
  %v66 = inttoptr i64 0 to ptr
  %v69 = add i64 0, 0
  call void @glm_tbl_get(ptr %v27, i64 %v69, ptr %ts20.dst)
  %v67 = load double, ptr %ts20.dst
  call void @glm_print_float(double %v67)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
