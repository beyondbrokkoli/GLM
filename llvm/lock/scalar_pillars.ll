@.str.0 = private unnamed_addr constant [12 x i8] c"Hello, glm!\00"
@.str.1 = private unnamed_addr constant [4 x i8] c"tab\00"
@.str.2 = private unnamed_addr constant [7 x i8] c"joined\00"
@.str.3 = private unnamed_addr constant [6 x i8] c"first\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"first\00"
@.str.5 = private unnamed_addr constant [7 x i8] c"second\00"
@.str.6 = private unnamed_addr constant [9 x i8] c"negative\00"
@.str.7 = private unnamed_addr constant [5 x i8] c"zero\00"
@.str.8 = private unnamed_addr constant [9 x i8] c"positive\00"
@.str.9 = private unnamed_addr constant [9 x i8] c"negative\00"
@.str.10 = private unnamed_addr constant [5 x i8] c"zero\00"
@.str.11 = private unnamed_addr constant [9 x i8] c"positive\00"
@.str.12 = private unnamed_addr constant [9 x i8] c"negative\00"
@.str.13 = private unnamed_addr constant [5 x i8] c"zero\00"
@.str.14 = private unnamed_addr constant [9 x i8] c"positive\00"
declare double @llvm.floor.f64(double)
declare void @glm_print_int(i64)
declare void @glm_print_float(double)
declare void @glm_print_bool(i1)
declare void @glm_print_string(ptr)
declare void @glm_print_sep()
declare void @glm_print_nl()

define i32 @main() {
entry:
  br label %b0

b0:
  %v0 = add i64 0, 10
  %v1 = add i64 0, 25
  %v6 = add i64 0, 2
  %v4 = mul i64 %v1, %v6
  %v2 = add i64 %v0, %v4
  call void @glm_print_int(i64 %v2)
  call void @glm_print_nl()
  %v8 = sub i64 0, %v1
  %v10 = add i64 0, 18
  %v7 = add i64 %v8, %v10
  call void @glm_print_int(i64 %v7)
  call void @glm_print_nl()
  %v12 = add i64 0, 7
  %v13 = add i64 0, 2
  %t11.0 = sdiv i64 %v12, %v13
  %t11.1 = srem i64 %v12, %v13
  %t11.2 = icmp ne i64 %t11.1, 0
  %t11.3 = xor i64 %v12, %v13
  %t11.4 = icmp slt i64 %t11.3, 0
  %t11.5 = and i1 %t11.2, %t11.4
  %t11.6 = sub i64 %t11.0, 1
  %v11 = select i1 %t11.5, i64 %t11.6, i64 %t11.0
  call void @glm_print_int(i64 %v11)
  call void @glm_print_nl()
  %v15 = add i64 0, 7
  %v16 = add i64 0, 2
  %t14.0 = srem i64 %v15, %v16
  %t14.1 = icmp ne i64 %t14.0, 0
  %t14.2 = xor i64 %t14.0, %v16
  %t14.3 = icmp slt i64 %t14.2, 0
  %t14.4 = and i1 %t14.1, %t14.3
  %t14.5 = add i64 %t14.0, %v16
  %v14 = select i1 %t14.4, i64 %t14.5, i64 %t14.0
  call void @glm_print_int(i64 %v14)
  call void @glm_print_nl()
  %v17 = fadd double 0.0, 2.5
  %v20 = fadd double 0.0, 2.0
  %v18 = fmul double %v17, %v20
  call void @glm_print_float(double %v18)
  call void @glm_print_nl()
  %v22 = fadd double 0.0, 7.0
  %v23 = fadd double 0.0, 2.0
  %v21 = fdiv double %v22, %v23
  call void @glm_print_float(double %v21)
  call void @glm_print_nl()
  %v26 = add i64 0, 7
  %v25 = sub i64 0, %v26
  %v27 = add i64 0, 2
  %t24.0 = sdiv i64 %v25, %v27
  %t24.1 = srem i64 %v25, %v27
  %t24.2 = icmp ne i64 %t24.1, 0
  %t24.3 = xor i64 %v25, %v27
  %t24.4 = icmp slt i64 %t24.3, 0
  %t24.5 = and i1 %t24.2, %t24.4
  %t24.6 = sub i64 %t24.0, 1
  %v24 = select i1 %t24.5, i64 %t24.6, i64 %t24.0
  call void @glm_print_int(i64 %v24)
  call void @glm_print_nl()
  %v29 = add i64 0, 7
  %v31 = add i64 0, 2
  %v30 = sub i64 0, %v31
  %t28.0 = sdiv i64 %v29, %v30
  %t28.1 = srem i64 %v29, %v30
  %t28.2 = icmp ne i64 %t28.1, 0
  %t28.3 = xor i64 %v29, %v30
  %t28.4 = icmp slt i64 %t28.3, 0
  %t28.5 = and i1 %t28.2, %t28.4
  %t28.6 = sub i64 %t28.0, 1
  %v28 = select i1 %t28.5, i64 %t28.6, i64 %t28.0
  call void @glm_print_int(i64 %v28)
  call void @glm_print_nl()
  %v34 = add i64 0, 7
  %v33 = sub i64 0, %v34
  %v36 = add i64 0, 2
  %v35 = sub i64 0, %v36
  %t32.0 = sdiv i64 %v33, %v35
  %t32.1 = srem i64 %v33, %v35
  %t32.2 = icmp ne i64 %t32.1, 0
  %t32.3 = xor i64 %v33, %v35
  %t32.4 = icmp slt i64 %t32.3, 0
  %t32.5 = and i1 %t32.2, %t32.4
  %t32.6 = sub i64 %t32.0, 1
  %v32 = select i1 %t32.5, i64 %t32.6, i64 %t32.0
  call void @glm_print_int(i64 %v32)
  call void @glm_print_nl()
  %v39 = add i64 0, 7
  %v38 = sub i64 0, %v39
  %v40 = add i64 0, 2
  %t37.0 = srem i64 %v38, %v40
  %t37.1 = icmp ne i64 %t37.0, 0
  %t37.2 = xor i64 %t37.0, %v40
  %t37.3 = icmp slt i64 %t37.2, 0
  %t37.4 = and i1 %t37.1, %t37.3
  %t37.5 = add i64 %t37.0, %v40
  %v37 = select i1 %t37.4, i64 %t37.5, i64 %t37.0
  call void @glm_print_int(i64 %v37)
  call void @glm_print_nl()
  %v42 = add i64 0, 7
  %v44 = add i64 0, 2
  %v43 = sub i64 0, %v44
  %t41.0 = srem i64 %v42, %v43
  %t41.1 = icmp ne i64 %t41.0, 0
  %t41.2 = xor i64 %t41.0, %v43
  %t41.3 = icmp slt i64 %t41.2, 0
  %t41.4 = and i1 %t41.1, %t41.3
  %t41.5 = add i64 %t41.0, %v43
  %v41 = select i1 %t41.4, i64 %t41.5, i64 %t41.0
  call void @glm_print_int(i64 %v41)
  call void @glm_print_nl()
  %v47 = add i64 0, 7
  %v46 = sub i64 0, %v47
  %v49 = add i64 0, 2
  %v48 = sub i64 0, %v49
  %t45.0 = srem i64 %v46, %v48
  %t45.1 = icmp ne i64 %t45.0, 0
  %t45.2 = xor i64 %t45.0, %v48
  %t45.3 = icmp slt i64 %t45.2, 0
  %t45.4 = and i1 %t45.1, %t45.3
  %t45.5 = add i64 %t45.0, %v48
  %v45 = select i1 %t45.4, i64 %t45.5, i64 %t45.0
  call void @glm_print_int(i64 %v45)
  call void @glm_print_nl()
  %v51 = add i64 0, 6
  %v53 = add i64 0, 3
  %v52 = sub i64 0, %v53
  %t50.0 = srem i64 %v51, %v52
  %t50.1 = icmp ne i64 %t50.0, 0
  %t50.2 = xor i64 %t50.0, %v52
  %t50.3 = icmp slt i64 %t50.2, 0
  %t50.4 = and i1 %t50.1, %t50.3
  %t50.5 = add i64 %t50.0, %v52
  %v50 = select i1 %t50.4, i64 %t50.5, i64 %t50.0
  call void @glm_print_int(i64 %v50)
  call void @glm_print_nl()
  %v56 = fadd double 0.0, 7.5
  %v55 = fsub double 0.0, %v56
  %v57 = fadd double 0.0, 2.0
  %t54.0 = fdiv double %v55, %v57
  %v54 = call double @llvm.floor.f64(double %t54.0)
  call void @glm_print_float(double %v54)
  call void @glm_print_nl()
  %v59 = fadd double 0.0, 7.5
  %v61 = fadd double 0.0, 2.0
  %v60 = fsub double 0.0, %v61
  %t58.0 = fdiv double %v59, %v60
  %v58 = call double @llvm.floor.f64(double %t58.0)
  call void @glm_print_float(double %v58)
  call void @glm_print_nl()
  %v64 = fadd double 0.0, 7.5
  %v63 = fsub double 0.0, %v64
  %v65 = fadd double 0.0, 2.0
  %t62.0 = frem double %v63, %v65
  %t62.1 = fcmp ogt double %t62.0, 0.0
  %t62.2 = fcmp olt double %v65, 0.0
  %t62.3 = and i1 %t62.1, %t62.2
  %t62.4 = fcmp olt double %t62.0, 0.0
  %t62.5 = fcmp ogt double %v65, 0.0
  %t62.6 = and i1 %t62.4, %t62.5
  %t62.7 = or i1 %t62.3, %t62.6
  %t62.8 = fadd double %t62.0, %v65
  %v62 = select i1 %t62.7, double %t62.8, double %t62.0
  call void @glm_print_float(double %v62)
  call void @glm_print_nl()
  %v67 = fadd double 0.0, 7.5
  %v69 = fadd double 0.0, 2.0
  %v68 = fsub double 0.0, %v69
  %t66.0 = frem double %v67, %v68
  %t66.1 = fcmp ogt double %t66.0, 0.0
  %t66.2 = fcmp olt double %v68, 0.0
  %t66.3 = and i1 %t66.1, %t66.2
  %t66.4 = fcmp olt double %t66.0, 0.0
  %t66.5 = fcmp ogt double %v68, 0.0
  %t66.6 = and i1 %t66.4, %t66.5
  %t66.7 = or i1 %t66.3, %t66.6
  %t66.8 = fadd double %t66.0, %v68
  %v66 = select i1 %t66.7, double %t66.8, double %t66.0
  call void @glm_print_float(double %v66)
  call void @glm_print_nl()
  %v72 = fadd double 0.0, 7.5
  %v71 = fsub double 0.0, %v72
  %v74 = fadd double 0.0, 2.0
  %v73 = fsub double 0.0, %v74
  %t70.0 = frem double %v71, %v73
  %t70.1 = fcmp ogt double %t70.0, 0.0
  %t70.2 = fcmp olt double %v73, 0.0
  %t70.3 = and i1 %t70.1, %t70.2
  %t70.4 = fcmp olt double %t70.0, 0.0
  %t70.5 = fcmp ogt double %v73, 0.0
  %t70.6 = and i1 %t70.4, %t70.5
  %t70.7 = or i1 %t70.3, %t70.6
  %t70.8 = fadd double %t70.0, %v73
  %v70 = select i1 %t70.7, double %t70.8, double %t70.0
  call void @glm_print_float(double %v70)
  call void @glm_print_nl()
  %v75 = add i64 0, 0
  %v76 = add i64 0, 1
  br label %b1

b1:
  %v77 = phi i64 [ %v75, %b0 ], [ %v90, %b6 ]
  %v78 = phi i64 [ %v76, %b0 ], [ %v91, %b6 ]
  %v81 = add i64 0, 5
  %v79 = icmp sle i64 %v78, %v81
  br i1 %v79, label %b2, label %b3

b2:
  %v85 = add i64 0, 2
  %t83.0 = srem i64 %v78, %v85
  %t83.1 = icmp ne i64 %t83.0, 0
  %t83.2 = xor i64 %t83.0, %v85
  %t83.3 = icmp slt i64 %t83.2, 0
  %t83.4 = and i1 %t83.1, %t83.3
  %t83.5 = add i64 %t83.0, %v85
  %v83 = select i1 %t83.4, i64 %t83.5, i64 %t83.0
  %v86 = add i64 0, 0
  %v82 = icmp eq i64 %v83, %v86
  br i1 %v82, label %b4, label %b5

b3:
  call void @glm_print_int(i64 %v77)
  call void @glm_print_nl()
  %v97 = or i1 0, 1
  br i1 %v97, label %b7, label %b8

b4:
  %v87 = add i64 %v77, %v78
  br label %b6

b5:
  br label %b6

b6:
  %v90 = phi i64 [ %v87, %b4 ], [ %v77, %b5 ]
  %v93 = add i64 0, 1
  %v91 = add i64 %v78, %v93
  br label %b1

b7:
  %v98 = or i1 0, 0
  br label %b9

b8:
  %v99 = or i1 0, 0
  br label %b9

b9:
  %v96 = phi i1 [ %v98, %b7 ], [ %v99, %b8 ]
  br i1 %v96, label %b10, label %b11

b10:
  %v101 = or i1 0, 1
  br label %b12

b11:
  %v100 = or i1 0, 1
  br label %b12

b12:
  %v95 = phi i1 [ %v101, %b10 ], [ %v100, %b11 ]
  call void @glm_print_bool(i1 %v95)
  call void @glm_print_nl()
  %v104 = add i64 0, 1
  %v105 = add i64 0, 2
  %v103 = icmp slt i64 %v104, %v105
  br i1 %v103, label %b13, label %b14

b13:
  %v107 = add i64 0, 2
  %v108 = add i64 0, 1
  %v106 = icmp slt i64 %v107, %v108
  br label %b15

b14:
  %v109 = or i1 0, 0
  br label %b15

b15:
  %v102 = phi i1 [ %v106, %b13 ], [ %v109, %b14 ]
  call void @glm_print_bool(i1 %v102)
  call void @glm_print_nl()
  %v112 = add i64 0, 3
  %v113 = add i64 0, 4
  %v111 = icmp eq i64 %v112, %v113
  %v110 = xor i1 %v111, 1
  call void @glm_print_bool(i1 %v110)
  call void @glm_print_nl()
  %v116 = or i1 0, 1
  %v117 = or i1 0, 0
  %v115 = icmp eq i1 %v116, %v117
  call void @glm_print_bool(i1 %v115)
  call void @glm_print_nl()
  %v118 = or i1 0, 1
  %v119 = add i64 0, 0
  br label %b16

b16:
  %v120 = phi i1 [ %v118, %b15 ], [ %v129, %b21 ]
  %v121 = phi i64 [ %v119, %b15 ], [ %v130, %b21 ]
  %v124 = add i64 0, 4
  %v122 = icmp slt i64 %v121, %v124
  br i1 %v122, label %b17, label %b18

b17:
  %v127 = add i64 0, 2
  %v125 = icmp eq i64 %v121, %v127
  br i1 %v125, label %b19, label %b20

b18:
  call void @glm_print_bool(i1 %v120)
  call void @glm_print_nl()
  %v134 = getelementptr inbounds [12 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v134)
  call void @glm_print_nl()
  %v136 = getelementptr inbounds [4 x i8], ptr @.str.1, i64 0, i64 0
  %v137 = getelementptr inbounds [7 x i8], ptr @.str.2, i64 0, i64 0
  call void @glm_print_string(ptr %v136)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v137)
  call void @glm_print_nl()
  %v138 = getelementptr inbounds [6 x i8], ptr @.str.3, i64 0, i64 0
  %v140 = add i64 0, 1
  %v141 = add i64 0, 2
  %v139 = icmp slt i64 %v141, %v140
  br i1 %v139, label %b22, label %b23

b19:
  %v128 = or i1 0, 0
  br label %b21

b20:
  br label %b21

b21:
  %v129 = phi i1 [ %v128, %b19 ], [ %v120, %b20 ]
  %v132 = add i64 0, 1
  %v130 = add i64 %v121, %v132
  br label %b16

b22:
  %v142 = getelementptr inbounds [6 x i8], ptr @.str.4, i64 0, i64 0
  br label %b24

b23:
  %v143 = getelementptr inbounds [7 x i8], ptr @.str.5, i64 0, i64 0
  br label %b24

b24:
  %v144 = phi ptr [ %v142, %b22 ], [ %v143, %b23 ]
  call void @glm_print_string(ptr %v144)
  call void @glm_print_nl()
  %v147 = add i64 0, 5
  %v146 = sub i64 0, %v147
  %v150 = add i64 0, 0
  %v148 = icmp slt i64 %v146, %v150
  br i1 %v148, label %b25, label %b26

b25:
  %v151 = getelementptr inbounds [9 x i8], ptr @.str.6, i64 0, i64 0
  call void @glm_print_string(ptr %v151)
  call void @glm_print_nl()
  br label %b27

b26:
  %v154 = add i64 0, 0
  %v152 = icmp eq i64 %v146, %v154
  br i1 %v152, label %b28, label %b29

b27:
  %v157 = add i64 0, 0
  %v160 = add i64 0, 0
  %v158 = icmp slt i64 %v157, %v160
  br i1 %v158, label %b31, label %b32

b28:
  %v155 = getelementptr inbounds [5 x i8], ptr @.str.7, i64 0, i64 0
  call void @glm_print_string(ptr %v155)
  call void @glm_print_nl()
  br label %b30

b29:
  %v156 = getelementptr inbounds [9 x i8], ptr @.str.8, i64 0, i64 0
  call void @glm_print_string(ptr %v156)
  call void @glm_print_nl()
  br label %b30

b30:
  br label %b27

b31:
  %v161 = getelementptr inbounds [9 x i8], ptr @.str.9, i64 0, i64 0
  call void @glm_print_string(ptr %v161)
  call void @glm_print_nl()
  br label %b33

b32:
  %v164 = add i64 0, 0
  %v162 = icmp eq i64 %v157, %v164
  br i1 %v162, label %b34, label %b35

b33:
  %v167 = add i64 0, 5
  %v170 = add i64 0, 0
  %v168 = icmp slt i64 %v167, %v170
  br i1 %v168, label %b37, label %b38

b34:
  %v165 = getelementptr inbounds [5 x i8], ptr @.str.10, i64 0, i64 0
  call void @glm_print_string(ptr %v165)
  call void @glm_print_nl()
  br label %b36

b35:
  %v166 = getelementptr inbounds [9 x i8], ptr @.str.11, i64 0, i64 0
  call void @glm_print_string(ptr %v166)
  call void @glm_print_nl()
  br label %b36

b36:
  br label %b33

b37:
  %v171 = getelementptr inbounds [9 x i8], ptr @.str.12, i64 0, i64 0
  call void @glm_print_string(ptr %v171)
  call void @glm_print_nl()
  br label %b39

b38:
  %v174 = add i64 0, 0
  %v172 = icmp eq i64 %v167, %v174
  br i1 %v172, label %b40, label %b41

b39:
  %v177 = add i64 0, 0
  %v178 = add i64 0, 10
  br label %b43

b40:
  %v175 = getelementptr inbounds [5 x i8], ptr @.str.13, i64 0, i64 0
  call void @glm_print_string(ptr %v175)
  call void @glm_print_nl()
  br label %b42

b41:
  %v176 = getelementptr inbounds [9 x i8], ptr @.str.14, i64 0, i64 0
  call void @glm_print_string(ptr %v176)
  call void @glm_print_nl()
  br label %b42

b42:
  br label %b39

b43:
  %v179 = phi i64 [ %v177, %b39 ], [ %v189, %b44 ]
  %v180 = phi i64 [ %v178, %b39 ], [ %v192, %b44 ]
  %v184 = add i64 0, 5
  %v182 = icmp slt i64 %v179, %v184
  br i1 %v182, label %b46, label %b47

b44:
  %v191 = add i64 0, 1
  %v189 = add i64 %v179, %v191
  %v194 = add i64 0, 1
  %v192 = sub i64 %v180, %v194
  br label %b43

b45:
  call void @glm_print_int(i64 %v179)
  call void @glm_print_nl()
  call void @glm_print_int(i64 %v180)
  call void @glm_print_nl()
  %v197 = add i64 0, 1
  %v199 = add i64 0, 0
  %v200 = add i64 0, 1
  %v198 = icmp slt i64 %v199, %v200
  br i1 %v198, label %b49, label %b50

b46:
  %v187 = add i64 0, 5
  %v185 = icmp slt i64 %v187, %v180
  br label %b48

b47:
  %v188 = or i1 0, 0
  br label %b48

b48:
  %v181 = phi i1 [ %v185, %b46 ], [ %v188, %b47 ]
  br i1 %v181, label %b44, label %b45

b49:
  %v201 = add i64 0, 100
  call void @glm_print_int(i64 %v201)
  call void @glm_print_nl()
  br label %b51

b50:
  br label %b51

b51:
  call void @glm_print_int(i64 %v197)
  call void @glm_print_nl()
  %v206 = add i64 0, 1
  %v207 = add i64 0, 0
  %v205 = icmp slt i64 %v206, %v207
  %v204 = xor i1 %v205, 1
  call void @glm_print_bool(i1 %v204)
  call void @glm_print_nl()
  ret i32 0
}
