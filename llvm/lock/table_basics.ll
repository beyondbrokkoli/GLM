@.str.0 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"world\00"
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
  %ts21.valp = alloca i8
  %ts22.valp = alloca i8
  %ts23.dst = alloca i8
  %ts24.dst = alloca i8
  %ts25.dst = alloca i8
  %ts27.dst = alloca i8
  %ts28.valp = alloca i8
  %ts29.dst = alloca i8
  %ts30.dst = alloca i8
  %ts31.valp = alloca ptr
  %ts32.valp = alloca ptr
  %ts33.dst = alloca ptr
  %ts34.dst = alloca ptr
  %ts36.dst = alloca ptr
  %ts37.valp = alloca double
  %ts38.valp = alloca double
  %ts39.dst = alloca double
  %ts41.dst = alloca double
  %ts42.valp = alloca i64
  %ts45.valp = alloca i64
  %ts46.valp = alloca i64
  %ts47.valp = alloca i64
  %ts48.valp = alloca i64
  %ts49.dst = alloca i64
  %ts50.valp = alloca i64
  %ts51.valp = alloca i64
  %ts52.valp = alloca i64
  %ts53.valp = alloca i64
  %ts54.valp = alloca i64
  %ts55.dst = alloca i64
  %ts56.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = fadd double 0.0, 1.5
  store double %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v5 = add i64 0, 1
  %v6 = fadd double 0.0, 2.5
  store double %v6, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v5, ptr %ts1.valp)
  %v7 = call i64 @glm_tbl_len(ptr %v0)
  %v11 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v11, ptr %ts3.dst)
  %v9 = load double, ptr %ts3.dst
  %v14 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v14, ptr %ts4.dst)
  %v12 = load double, ptr %ts4.dst
  %v17 = add i64 0, 2
  call void @glm_tbl_get(ptr %v0, i64 %v17, ptr %ts5.dst)
  %v15 = load double, ptr %ts5.dst
  call void @glm_print_int(i64 %v7)
  call void @glm_print_sep()
  call void @glm_print_float(double %v9)
  call void @glm_print_sep()
  call void @glm_print_float(double %v12)
  call void @glm_print_sep()
  call void @glm_print_float(double %v15)
  call void @glm_print_nl()
  %v19 = add i64 0, 10
  %v20 = fadd double 0.0, 7.25
  store double %v20, ptr %ts6.valp
  call void @glm_tbl_set(ptr %v0, i64 %v19, ptr %ts6.valp)
  %v21 = call i64 @glm_tbl_len(ptr %v0)
  %v25 = add i64 0, 5
  call void @glm_tbl_get(ptr %v0, i64 %v25, ptr %ts8.dst)
  %v23 = load double, ptr %ts8.dst
  %v28 = add i64 0, 10
  call void @glm_tbl_get(ptr %v0, i64 %v28, ptr %ts9.dst)
  %v26 = load double, ptr %ts9.dst
  call void @glm_print_int(i64 %v21)
  call void @glm_print_sep()
  call void @glm_print_float(double %v23)
  call void @glm_print_sep()
  call void @glm_print_float(double %v26)
  call void @glm_print_nl()
  %v29 = getelementptr i8, ptr %v0, i64 0
  %v31 = add i64 0, 20
  %v32 = fadd double 0.0, 1.125
  store double %v32, ptr %ts10.valp
  call void @glm_tbl_set(ptr %v29, i64 %v31, ptr %ts10.valp)
  %v33 = call i64 @glm_tbl_len(ptr %v0)
  %v37 = add i64 0, 20
  call void @glm_tbl_get(ptr %v0, i64 %v37, ptr %ts12.dst)
  %v35 = load double, ptr %ts12.dst
  %v40 = add i64 0, 1
  call void @glm_tbl_get(ptr %v29, i64 %v40, ptr %ts13.dst)
  %v38 = load double, ptr %ts13.dst
  call void @glm_print_int(i64 %v33)
  call void @glm_print_sep()
  call void @glm_print_float(double %v35)
  call void @glm_print_sep()
  call void @glm_print_float(double %v38)
  call void @glm_print_nl()
  %v41 = add i64 0, 0
  %v42 = add i64 0, 24
  call void @glm_tbl_reserve(ptr %v0, i64 %v42)
  br label %b1

b1:
  %v43 = phi i64 [ %v41, %b0 ], [ %v54, %bts15cont ]
  %v44 = icmp slt i64 %v43, %v42
  br i1 %v44, label %b2, label %b3

b2:
  call void @glm_tbl_get(ptr %v0, i64 %v43, ptr %ts14.dst)
  %v49 = load double, ptr %ts14.dst
  %v52 = fadd double 0.0, 2.0
  %v48 = fmul double %v49, %v52
  %v53 = fadd double 0.0, 0.5
  %v47 = fadd double %v48, %v53
%ts15.d = load ptr, ptr %v0, !alias.scope !0
%ts15.s = getelementptr inbounds double, ptr %ts15.d, i64 %v43
store double %v47, ptr %ts15.s, !noalias !0
br label %bts15cont

bts15cont:
  %v56 = add i64 0, 1
  %v54 = add i64 %v43, %v56
  br label %b1

b3:
  %v59 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v59, ptr %ts16.dst)
  %v57 = load double, ptr %ts16.dst
  %v62 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v62, ptr %ts17.dst)
  %v60 = load double, ptr %ts17.dst
  %v65 = add i64 0, 23
  call void @glm_tbl_get(ptr %v0, i64 %v65, ptr %ts18.dst)
  %v63 = load double, ptr %ts18.dst
  %v66 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_float(double %v57)
  call void @glm_print_sep()
  call void @glm_print_float(double %v60)
  call void @glm_print_sep()
  call void @glm_print_float(double %v63)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v66)
  call void @glm_print_nl()
  %v68 = inttoptr i64 0 to ptr
  %v71 = add i64 0, 0
  call void @glm_tbl_get(ptr %v29, i64 %v71, ptr %ts20.dst)
  %v69 = load double, ptr %ts20.dst
  call void @glm_print_float(double %v69)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v0)
  %v72 = call ptr @glm_tbl_new(i64 1, i8 0)
  %v74 = add i64 0, 0
  %v75 = or i1 0, 1
  %ts21.z = zext i1 %v75 to i8
store i8 %ts21.z, ptr %ts21.valp
  call void @glm_tbl_set(ptr %v72, i64 %v74, ptr %ts21.valp)
  %v77 = add i64 0, 1
  %v78 = or i1 0, 0
  %ts22.z = zext i1 %v78 to i8
store i8 %ts22.z, ptr %ts22.valp
  call void @glm_tbl_set(ptr %v72, i64 %v77, ptr %ts22.valp)
  %v81 = add i64 0, 0
  call void @glm_tbl_get(ptr %v72, i64 %v81, ptr %ts23.dst)
  %ts23.c = load i8, ptr %ts23.dst
%v79 = icmp ne i8 %ts23.c, 0
  %v84 = add i64 0, 1
  call void @glm_tbl_get(ptr %v72, i64 %v84, ptr %ts24.dst)
  %ts24.c = load i8, ptr %ts24.dst
%v82 = icmp ne i8 %ts24.c, 0
  %v87 = add i64 0, 2
  call void @glm_tbl_get(ptr %v72, i64 %v87, ptr %ts25.dst)
  %ts25.c = load i8, ptr %ts25.dst
%v85 = icmp ne i8 %ts25.c, 0
  %v88 = call i64 @glm_tbl_len(ptr %v72)
  call void @glm_print_bool(i1 %v79)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v82)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v85)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v88)
  call void @glm_print_nl()
  %v90 = add i64 0, 0
  %v91 = add i64 0, 5
  call void @glm_tbl_reserve(ptr %v72, i64 %v91)
  br label %b4

b4:
  %v92 = phi i64 [ %v90, %b3 ], [ %v100, %bts28cont ]
  %v93 = icmp slt i64 %v92, %v91
  br i1 %v93, label %b5, label %b6

b5:
  call void @glm_tbl_get(ptr %v72, i64 %v92, ptr %ts27.dst)
  %ts27.c = load i8, ptr %ts27.dst
%v97 = icmp ne i8 %ts27.c, 0
  %v96 = xor i1 %v97, 1
  %ts28.c = zext i1 %v96 to i8
%ts28.d = load ptr, ptr %v72, !alias.scope !0
%ts28.s = getelementptr inbounds i8, ptr %ts28.d, i64 %v92
store i8 %ts28.c, ptr %ts28.s, !noalias !0
br label %bts28cont

bts28cont:
  %v102 = add i64 0, 1
  %v100 = add i64 %v92, %v102
  br label %b4

b6:
  %v105 = add i64 0, 0
  call void @glm_tbl_get(ptr %v72, i64 %v105, ptr %ts29.dst)
  %ts29.c = load i8, ptr %ts29.dst
%v103 = icmp ne i8 %ts29.c, 0
  %v108 = add i64 0, 3
  call void @glm_tbl_get(ptr %v72, i64 %v108, ptr %ts30.dst)
  %ts30.c = load i8, ptr %ts30.dst
%v106 = icmp ne i8 %ts30.c, 0
  call void @glm_print_bool(i1 %v103)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v106)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v72)
  %v109 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v111 = add i64 0, 0
  %v112 = getelementptr inbounds [6 x i8], ptr @.str.0, i64 0, i64 0
  store ptr %v112, ptr %ts31.valp
  call void @glm_tbl_set(ptr %v109, i64 %v111, ptr %ts31.valp)
  %v114 = add i64 0, 1
  %v115 = getelementptr inbounds [6 x i8], ptr @.str.1, i64 0, i64 0
  store ptr %v115, ptr %ts32.valp
  call void @glm_tbl_set(ptr %v109, i64 %v114, ptr %ts32.valp)
  %v118 = add i64 0, 0
  call void @glm_tbl_get(ptr %v109, i64 %v118, ptr %ts33.dst)
  %ts33.loaded = load i64, ptr %ts33.dst
%v116 = inttoptr i64 %ts33.loaded to ptr
  %v121 = add i64 0, 1
  call void @glm_tbl_get(ptr %v109, i64 %v121, ptr %ts34.dst)
  %ts34.loaded = load i64, ptr %ts34.dst
%v119 = inttoptr i64 %ts34.loaded to ptr
  %v122 = call i64 @glm_tbl_len(ptr %v109)
  call void @glm_print_string(ptr %v116)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v119)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v122)
  call void @glm_print_nl()
  %v124 = getelementptr i8, ptr %v109, i64 0
  %v127 = add i64 0, 1
  call void @glm_tbl_get(ptr %v124, i64 %v127, ptr %ts36.dst)
  %ts36.loaded = load i64, ptr %ts36.dst
%v125 = inttoptr i64 %ts36.loaded to ptr
  call void @glm_print_string(ptr %v125)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v109)
  %v128 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v130 = add i64 0, 0
  %v131 = fadd double 0.0, 1.5
  store double %v131, ptr %ts37.valp
  call void @glm_tbl_set(ptr %v128, i64 %v130, ptr %ts37.valp)
  %v132 = getelementptr i8, ptr %v128, i64 0
  %v134 = add i64 0, 1
  %v135 = fadd double 0.0, 2.5
  store double %v135, ptr %ts38.valp
  call void @glm_tbl_set(ptr %v132, i64 %v134, ptr %ts38.valp)
  %v138 = add i64 0, 0
  call void @glm_tbl_get(ptr %v128, i64 %v138, ptr %ts39.dst)
  %v136 = load double, ptr %ts39.dst
  %v139 = call i64 @glm_tbl_len(ptr %v128)
  %v143 = add i64 0, 1
  call void @glm_tbl_get(ptr %v132, i64 %v143, ptr %ts41.dst)
  %v141 = load double, ptr %ts41.dst
  call void @glm_print_float(double %v136)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v139)
  call void @glm_print_sep()
  call void @glm_print_float(double %v141)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v128)
  %v144 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v146 = add i64 0, 0
  %v147 = add i64 0, 1
  store i64 %v147, ptr %ts42.valp
  call void @glm_tbl_set(ptr %v144, i64 %v146, ptr %ts42.valp)
  %v148 = call i64 @glm_tbl_len(ptr %v144)
  call void @glm_print_int(i64 %v148)
  call void @glm_print_nl()
  %v150 = call ptr @glm_tbl_new(i64 1, i8 0)
  %v151 = call i64 @glm_tbl_len(ptr %v150)
  call void @glm_print_int(i64 %v151)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v150)
  call void @glm_tbl_free(ptr %v144)
  %v153 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v154 = getelementptr i8, ptr %v153, i64 0
  %v155 = icmp eq ptr %v153, %v154
  call void @glm_print_bool(i1 %v155)
  call void @glm_print_nl()
  %v160 = call ptr @glm_tbl_new(i64 1, i8 0)
  %v158 = icmp eq ptr %v153, %v160
  call void @glm_print_bool(i1 %v158)
  call void @glm_print_nl()
  %v162 = add i64 0, 0
  %v163 = add i64 0, 1
  store i64 %v163, ptr %ts45.valp
  call void @glm_tbl_set(ptr %v154, i64 %v162, ptr %ts45.valp)
  %v164 = icmp eq ptr %v153, %v154
  call void @glm_print_bool(i1 %v164)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v153)
  %v167 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v169 = add i64 0, 0
  %v170 = add i64 0, 1
  store i64 %v170, ptr %ts46.valp
  call void @glm_tbl_set(ptr %v167, i64 %v169, ptr %ts46.valp)
  %v172 = add i64 0, 1
  %v173 = add i64 0, 2
  store i64 %v173, ptr %ts47.valp
  call void @glm_tbl_set(ptr %v167, i64 %v172, ptr %ts47.valp)
  %v175 = add i64 0, 2
  %v176 = add i64 0, 3
  store i64 %v176, ptr %ts48.valp
  call void @glm_tbl_set(ptr %v167, i64 %v175, ptr %ts48.valp)
  %v179 = add i64 0, 0
  call void @glm_tbl_get(ptr %v167, i64 %v179, ptr %ts49.dst)
  %v177 = load i64, ptr %ts49.dst
  call void @glm_print_int(i64 %v177)
  call void @glm_print_nl()
  %v180 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v182 = add i64 0, 0
  %v183 = add i64 0, 10
  store i64 %v183, ptr %ts50.valp
  call void @glm_tbl_set(ptr %v180, i64 %v182, ptr %ts50.valp)
  %v185 = add i64 0, 1
  %v186 = add i64 0, 20
  store i64 %v186, ptr %ts51.valp
  call void @glm_tbl_set(ptr %v180, i64 %v185, ptr %ts51.valp)
  %v188 = add i64 0, 2
  %v189 = add i64 0, 30
  store i64 %v189, ptr %ts52.valp
  call void @glm_tbl_set(ptr %v180, i64 %v188, ptr %ts52.valp)
  %v191 = add i64 0, 3
  %v192 = add i64 0, 40
  store i64 %v192, ptr %ts53.valp
  call void @glm_tbl_set(ptr %v180, i64 %v191, ptr %ts53.valp)
  %v194 = add i64 0, 4
  %v195 = add i64 0, 50
  store i64 %v195, ptr %ts54.valp
  call void @glm_tbl_set(ptr %v180, i64 %v194, ptr %ts54.valp)
  %v198 = add i64 0, 0
  call void @glm_tbl_get(ptr %v180, i64 %v198, ptr %ts55.dst)
  %v196 = load i64, ptr %ts55.dst
  call void @glm_print_int(i64 %v196)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v180)
  %v201 = add i64 0, 1
  call void @glm_tbl_get(ptr %v167, i64 %v201, ptr %ts56.dst)
  %v199 = load i64, ptr %ts56.dst
  call void @glm_print_int(i64 %v199)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v167)
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
