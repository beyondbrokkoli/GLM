@.str.0 = private unnamed_addr constant [43 x i8] c"=== 1. Basic Types & Strict Arithmetic ===\00"
@.str.1 = private unnamed_addr constant [9 x i8] c"Int Ops:\00"
@.str.2 = private unnamed_addr constant [11 x i8] c"Float Ops:\00"
@.str.3 = private unnamed_addr constant [32 x i8] c"=== 2. Control Flow & Logic ===\00"
@.str.4 = private unnamed_addr constant [4 x i8] c"Hot\00"
@.str.5 = private unnamed_addr constant [7 x i8] c"Logic:\00"
@.str.6 = private unnamed_addr constant [5 x i8] c"Cold\00"
@.str.7 = private unnamed_addr constant [5 x i8] c"Mild\00"
@.str.8 = private unnamed_addr constant [26 x i8] c"=== 3. Integer Tables ===\00"
@.str.9 = private unnamed_addr constant [8 x i8] c"Length:\00"
@.str.10 = private unnamed_addr constant [10 x i8] c"Elements:\00"
@.str.11 = private unnamed_addr constant [24 x i8] c"=== 4. Float Tables ===\00"
@.str.12 = private unnamed_addr constant [7 x i8] c"Temps:\00"
@.str.13 = private unnamed_addr constant [26 x i8] c"=== 5. Boolean Tables ===\00"
@.str.14 = private unnamed_addr constant [7 x i8] c"Flags:\00"
@.str.15 = private unnamed_addr constant [25 x i8] c"=== 6. String Tables ===\00"
@.str.16 = private unnamed_addr constant [4 x i8] c"GLM\00"
@.str.17 = private unnamed_addr constant [9 x i8] c"Compiler\00"
@.str.18 = private unnamed_addr constant [5 x i8] c"Rust\00"
@.str.19 = private unnamed_addr constant [7 x i8] c"Names:\00"
@.str.20 = private unnamed_addr constant [31 x i8] c"=== 7. Lifetime Management ===\00"
@.str.21 = private unnamed_addr constant [11 x i8] c"Cache hit:\00"
@.str.22 = private unnamed_addr constant [22 x i8] c"Cache released safely\00"
@.str.23 = private unnamed_addr constant [26 x i8] c"=== Showcase Complete ===\00"
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
  %ts2.dst = alloca i64
  %ts3.dst = alloca i64
  %ts4.dst = alloca i64
  %ts5.dst = alloca i64
  %ts6.dst = alloca i64
  %ts7.valp = alloca double
  %ts8.dst = alloca double
  %ts9.dst = alloca double
  %ts10.dst = alloca double
  %ts11.valp = alloca i8
  %ts12.dst = alloca i8
  %ts13.dst = alloca i8
  %ts14.dst = alloca i8
  %ts15.dst = alloca i8
  %ts16.valp = alloca ptr
  %ts17.valp = alloca ptr
  %ts18.valp = alloca ptr
  %ts19.dst = alloca ptr
  %ts20.dst = alloca ptr
  %ts21.dst = alloca ptr
  %ts22.valp = alloca i64
  %ts23.dst = alloca i64
  br label %b0

b0:
  %v0 = getelementptr inbounds [43 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v0)
  call void @glm_print_nl()
  %v1 = add i64 0, 17
  %v2 = add i64 0, 5
  %v3 = getelementptr inbounds [9 x i8], ptr @.str.1, i64 0, i64 0
  %v4 = add i64 %v1, %v2
  %v7 = sub i64 %v1, %v2
  %v10 = mul i64 %v1, %v2
  %v13 = sdiv i64 %v1, %v2
  %t16.0 = sdiv i64 %v1, %v2
  %t16.1 = srem i64 %v1, %v2
  %t16.2 = icmp ne i64 %t16.1, 0
  %t16.3 = xor i64 %v1, %v2
  %t16.4 = icmp slt i64 %t16.3, 0
  %t16.5 = and i1 %t16.2, %t16.4
  %t16.6 = sub i64 %t16.0, 1
  %v16 = select i1 %t16.5, i64 %t16.6, i64 %t16.0
  %t19.0 = srem i64 %v1, %v2
  %t19.1 = icmp ne i64 %t19.0, 0
  %t19.2 = xor i64 %t19.0, %v2
  %t19.3 = icmp slt i64 %t19.2, 0
  %t19.4 = and i1 %t19.1, %t19.3
  %t19.5 = add i64 %t19.0, %v2
  %v19 = select i1 %t19.4, i64 %t19.5, i64 %t19.0
  call void @glm_print_string(ptr %v3)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v4)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v7)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v10)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v13)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v16)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v19)
  call void @glm_print_nl()
  %v22 = fadd double 0.0, 3.14159
  %v23 = fadd double 0.0, 2.0
  %v26 = fmul double %v23, %v23
  %v24 = fmul double %v22, %v26
  %v29 = getelementptr inbounds [11 x i8], ptr @.str.2, i64 0, i64 0
  call void @glm_print_string(ptr %v29)
  call void @glm_print_sep()
  call void @glm_print_float(double %v24)
  call void @glm_print_nl()
  %v31 = getelementptr inbounds [32 x i8], ptr @.str.3, i64 0, i64 0
  call void @glm_print_string(ptr %v31)
  call void @glm_print_nl()
  %v32 = add i64 0, 25
  %v35 = add i64 0, 30
  %v33 = icmp slt i64 %v35, %v32
  br i1 %v33, label %b1, label %b2

b1:
  %v36 = getelementptr inbounds [4 x i8], ptr @.str.4, i64 0, i64 0
  call void @glm_print_string(ptr %v36)
  call void @glm_print_nl()
  br label %b3

b2:
  %v39 = add i64 0, 10
  %v37 = icmp slt i64 %v32, %v39
  br i1 %v37, label %b4, label %b5

b3:
  %v42 = or i1 0, 1
  %v43 = or i1 0, 0
  %v44 = getelementptr inbounds [7 x i8], ptr @.str.5, i64 0, i64 0
  br i1 %v42, label %b7, label %b8

b4:
  %v40 = getelementptr inbounds [5 x i8], ptr @.str.6, i64 0, i64 0
  call void @glm_print_string(ptr %v40)
  call void @glm_print_nl()
  br label %b6

b5:
  %v41 = getelementptr inbounds [5 x i8], ptr @.str.7, i64 0, i64 0
  call void @glm_print_string(ptr %v41)
  call void @glm_print_nl()
  br label %b6

b6:
  br label %b3

b7:
  br label %b9

b8:
  %v48 = or i1 0, 0
  br label %b9

b9:
  %v45 = phi i1 [ %v43, %b7 ], [ %v48, %b8 ]
  br i1 %v42, label %b10, label %b11

b10:
  %v52 = or i1 0, 1
  br label %b12

b11:
  br label %b12

b12:
  %v49 = phi i1 [ %v52, %b10 ], [ %v43, %b11 ]
  %v53 = xor i1 %v43, 1
  call void @glm_print_string(ptr %v44)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v45)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v49)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v53)
  call void @glm_print_nl()
  %v55 = getelementptr inbounds [26 x i8], ptr @.str.8, i64 0, i64 0
  call void @glm_print_string(ptr %v55)
  call void @glm_print_nl()
  %v56 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v57 = add i64 0, 0
  %v58 = add i64 0, 5
  call void @glm_tbl_reserve(ptr %v56, i64 %v58)
  br label %b13

b13:
  %v59 = phi i64 [ %v57, %b12 ], [ %v66, %bts0cont ]
  %v60 = icmp slt i64 %v59, %v58
  br i1 %v60, label %b14, label %b15

b14:
  %v65 = add i64 0, 100
  %v63 = mul i64 %v59, %v65
%ts0.d = load ptr, ptr %v56, !alias.scope !0
%ts0.s = getelementptr inbounds i64, ptr %ts0.d, i64 %v59
store i64 %v63, ptr %ts0.s, !noalias !0
br label %bts0cont

bts0cont:
  %v68 = add i64 0, 1
  %v66 = add i64 %v59, %v68
  br label %b13

b15:
  %v69 = getelementptr inbounds [8 x i8], ptr @.str.9, i64 0, i64 0
  %v70 = call i64 @glm_tbl_len(ptr %v56)
  call void @glm_print_string(ptr %v69)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v70)
  call void @glm_print_nl()
  %v72 = getelementptr inbounds [10 x i8], ptr @.str.10, i64 0, i64 0
  %v75 = add i64 0, 0
  call void @glm_tbl_get(ptr %v56, i64 %v75, ptr %ts2.dst)
  %v73 = load i64, ptr %ts2.dst
  %v78 = add i64 0, 1
  call void @glm_tbl_get(ptr %v56, i64 %v78, ptr %ts3.dst)
  %v76 = load i64, ptr %ts3.dst
  %v81 = add i64 0, 2
  call void @glm_tbl_get(ptr %v56, i64 %v81, ptr %ts4.dst)
  %v79 = load i64, ptr %ts4.dst
  %v84 = add i64 0, 3
  call void @glm_tbl_get(ptr %v56, i64 %v84, ptr %ts5.dst)
  %v82 = load i64, ptr %ts5.dst
  %v87 = add i64 0, 4
  call void @glm_tbl_get(ptr %v56, i64 %v87, ptr %ts6.dst)
  %v85 = load i64, ptr %ts6.dst
  call void @glm_print_string(ptr %v72)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v73)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v76)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v79)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v82)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v85)
  call void @glm_print_nl()
  %v88 = getelementptr inbounds [24 x i8], ptr @.str.11, i64 0, i64 0
  call void @glm_print_string(ptr %v88)
  call void @glm_print_nl()
  %v89 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v90 = add i64 0, 0
  %v91 = add i64 0, 3
  call void @glm_tbl_reserve(ptr %v89, i64 %v91)
  br label %b16

b16:
  %v92 = phi i64 [ %v90, %b15 ], [ %v97, %bts7cont ]
  %v93 = icmp slt i64 %v92, %v91
  br i1 %v93, label %b17, label %b18

b17:
  %v96 = fadd double 0.0, 98.6
%ts7.d = load ptr, ptr %v89, !alias.scope !0
%ts7.s = getelementptr inbounds double, ptr %ts7.d, i64 %v92
store double %v96, ptr %ts7.s, !noalias !0
br label %bts7cont

bts7cont:
  %v99 = add i64 0, 1
  %v97 = add i64 %v92, %v99
  br label %b16

b18:
  %v100 = getelementptr inbounds [7 x i8], ptr @.str.12, i64 0, i64 0
  %v103 = add i64 0, 0
  call void @glm_tbl_get(ptr %v89, i64 %v103, ptr %ts8.dst)
  %v101 = load double, ptr %ts8.dst
  %v106 = add i64 0, 1
  call void @glm_tbl_get(ptr %v89, i64 %v106, ptr %ts9.dst)
  %v104 = load double, ptr %ts9.dst
  %v109 = add i64 0, 2
  call void @glm_tbl_get(ptr %v89, i64 %v109, ptr %ts10.dst)
  %v107 = load double, ptr %ts10.dst
  call void @glm_print_string(ptr %v100)
  call void @glm_print_sep()
  call void @glm_print_float(double %v101)
  call void @glm_print_sep()
  call void @glm_print_float(double %v104)
  call void @glm_print_sep()
  call void @glm_print_float(double %v107)
  call void @glm_print_nl()
  %v110 = getelementptr inbounds [26 x i8], ptr @.str.13, i64 0, i64 0
  call void @glm_print_string(ptr %v110)
  call void @glm_print_nl()
  %v111 = call ptr @glm_tbl_new(i64 1, i8 0)
  %v112 = add i64 0, 0
  %v113 = add i64 0, 4
  call void @glm_tbl_reserve(ptr %v111, i64 %v113)
  br label %b19

b19:
  %v114 = phi i64 [ %v112, %b18 ], [ %v119, %bts11cont ]
  %v115 = icmp slt i64 %v114, %v113
  br i1 %v115, label %b20, label %b21

b20:
  %v118 = or i1 0, 1
  %ts11.c = zext i1 %v118 to i8
%ts11.d = load ptr, ptr %v111, !alias.scope !0
%ts11.s = getelementptr inbounds i8, ptr %ts11.d, i64 %v114
store i8 %ts11.c, ptr %ts11.s, !noalias !0
br label %bts11cont

bts11cont:
  %v121 = add i64 0, 1
  %v119 = add i64 %v114, %v121
  br label %b19

b21:
  %v122 = getelementptr inbounds [7 x i8], ptr @.str.14, i64 0, i64 0
  %v125 = add i64 0, 0
  call void @glm_tbl_get(ptr %v111, i64 %v125, ptr %ts12.dst)
  %ts12.c = load i8, ptr %ts12.dst
%v123 = icmp ne i8 %ts12.c, 0
  %v128 = add i64 0, 1
  call void @glm_tbl_get(ptr %v111, i64 %v128, ptr %ts13.dst)
  %ts13.c = load i8, ptr %ts13.dst
%v126 = icmp ne i8 %ts13.c, 0
  %v131 = add i64 0, 2
  call void @glm_tbl_get(ptr %v111, i64 %v131, ptr %ts14.dst)
  %ts14.c = load i8, ptr %ts14.dst
%v129 = icmp ne i8 %ts14.c, 0
  %v134 = add i64 0, 3
  call void @glm_tbl_get(ptr %v111, i64 %v134, ptr %ts15.dst)
  %ts15.c = load i8, ptr %ts15.dst
%v132 = icmp ne i8 %ts15.c, 0
  call void @glm_print_string(ptr %v122)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v123)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v126)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v129)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v132)
  call void @glm_print_nl()
  %v135 = getelementptr inbounds [25 x i8], ptr @.str.15, i64 0, i64 0
  call void @glm_print_string(ptr %v135)
  call void @glm_print_nl()
  %v136 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v138 = add i64 0, 0
  %v139 = getelementptr inbounds [4 x i8], ptr @.str.16, i64 0, i64 0
  store ptr %v139, ptr %ts16.valp
  call void @glm_tbl_set(ptr %v136, i64 %v138, ptr %ts16.valp)
  %v141 = add i64 0, 1
  %v142 = getelementptr inbounds [9 x i8], ptr @.str.17, i64 0, i64 0
  store ptr %v142, ptr %ts17.valp
  call void @glm_tbl_set(ptr %v136, i64 %v141, ptr %ts17.valp)
  %v144 = add i64 0, 2
  %v145 = getelementptr inbounds [5 x i8], ptr @.str.18, i64 0, i64 0
  store ptr %v145, ptr %ts18.valp
  call void @glm_tbl_set(ptr %v136, i64 %v144, ptr %ts18.valp)
  %v146 = getelementptr inbounds [7 x i8], ptr @.str.19, i64 0, i64 0
  %v149 = add i64 0, 0
  call void @glm_tbl_get(ptr %v136, i64 %v149, ptr %ts19.dst)
  %v147 = load ptr, ptr %ts19.dst
  %v152 = add i64 0, 1
  call void @glm_tbl_get(ptr %v136, i64 %v152, ptr %ts20.dst)
  %v150 = load ptr, ptr %ts20.dst
  %v155 = add i64 0, 2
  call void @glm_tbl_get(ptr %v136, i64 %v155, ptr %ts21.dst)
  %v153 = load ptr, ptr %ts21.dst
  call void @glm_print_string(ptr %v146)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v147)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v150)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v153)
  call void @glm_print_nl()
  %v156 = getelementptr inbounds [31 x i8], ptr @.str.20, i64 0, i64 0
  call void @glm_print_string(ptr %v156)
  call void @glm_print_nl()
  %v157 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v159 = add i64 0, 0
  %v160 = add i64 0, 42
  store i64 %v160, ptr %ts22.valp
  call void @glm_tbl_set(ptr %v157, i64 %v159, ptr %ts22.valp)
  %v161 = getelementptr inbounds [11 x i8], ptr @.str.21, i64 0, i64 0
  %v164 = add i64 0, 0
  call void @glm_tbl_get(ptr %v157, i64 %v164, ptr %ts23.dst)
  %v162 = load i64, ptr %ts23.dst
  call void @glm_print_string(ptr %v161)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v162)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v157)
  %v165 = inttoptr i64 0 to ptr
  %v166 = getelementptr inbounds [22 x i8], ptr @.str.22, i64 0, i64 0
  call void @glm_print_string(ptr %v166)
  call void @glm_print_nl()
  %v167 = getelementptr inbounds [26 x i8], ptr @.str.23, i64 0, i64 0
  call void @glm_print_string(ptr %v167)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
