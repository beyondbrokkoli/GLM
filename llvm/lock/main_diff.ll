@.str.0 = private unnamed_addr constant [24 x i8] c"TABLE 17 (Phase N) FOLD\00"
@.str.1 = private unnamed_addr constant [28 x i8] c"TABLE 18 (Phase O) CHECKSUM\00"
@.str.2 = private unnamed_addr constant [28 x i8] c"TABLE 19 (Phase Q) FAR CELL\00"
@.str.3 = private unnamed_addr constant [28 x i8] c"TABLE 20 (Phase R) CHECKSUM\00"
@.str.4 = private unnamed_addr constant [28 x i8] c"TABLE 21 (Phase U) CHECKSUM\00"
@.str.5 = private unnamed_addr constant [28 x i8] c"TABLE 22 (Phase Z) CHECKSUM\00"
declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_reserve(ptr, i64)
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
  %ts2.dst = alloca i64
  %ts3.dst = alloca i64
  %ts4.dst = alloca i64
  %ts5.valp = alloca i64
  %ts6.valp = alloca i64
  %ts7.dst = alloca i64
  %ts8.dst = alloca i64
  %ts9.valp = alloca i64
  %ts10.dst = alloca i64
  %ts11.valp = alloca i64
  %ts12.dst = alloca i64
  %ts13.valp = alloca i64
  %ts14.dst = alloca i64
  %ts15.valp = alloca i64
  %ts16.dst = alloca i64
  %ts17.valp = alloca i64
  %ts18.dst = alloca i64
  %ts19.valp = alloca i64
  %ts20.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v1 = add i64 0, 0
  %v2 = add i64 0, 4096
  call void @glm_tbl_reserve(ptr %v0, i64 %v2)
  br label %b1

b1:
  %v3 = phi i64 [ %v1, %b0 ], [ %v12, %bts0cont ]
  %v4 = icmp slt i64 %v3, %v2
  br i1 %v4, label %b2, label %b3

b2:
  %v8 = mul i64 %v3, %v3
  %v7 = sub i64 %v8, %v3
%ts0.d = load ptr, ptr %v0, !alias.scope !0
%ts0.s = getelementptr inbounds i64, ptr %ts0.d, i64 %v3
store i64 %v7, ptr %ts0.s, !noalias !0
br label %bts0cont

bts0cont:
  %v14 = add i64 0, 1
  %v12 = add i64 %v3, %v14
  br label %b1

b3:
  %v15 = add i64 0, 20000
  %v16 = add i64 0, 0
  %v17 = add i64 0, 0
  %v18 = add i64 0, 0
  %v19 = add i64 0, 0
  %v20 = add i64 0, 0
  br label %b4

b4:
  %v21 = phi i64 [ %v16, %b3 ], [ %v87, %b18 ]
  %v22 = phi i64 [ %v17, %b3 ], [ %v73, %b18 ]
  %v23 = phi i64 [ %v18, %b3 ], [ %v46, %b18 ]
  %v24 = phi i64 [ %v19, %b3 ], [ %v56, %b18 ]
  %v25 = phi i64 [ %v20, %b3 ], [ %v66, %b18 ]
  %v26 = icmp slt i64 %v21, %v15
  br i1 %v26, label %b5, label %b6

b5:
  %v29 = getelementptr i8, ptr %v0, i64 0
  %v30 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v31 = add i64 0, 0
  %v32 = add i64 0, 64
  call void @glm_tbl_reserve(ptr %v30, i64 %v32)
  br label %b7

b6:
  %v90 = getelementptr inbounds [24 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v90)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v22)
  call void @glm_print_nl()
  %v92 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v93 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v94 = add i64 0, 20000
  %v95 = add i64 0, 0
  br label %b19

b7:
  %v33 = phi i64 [ %v31, %b5 ], [ %v40, %bts1cont ]
  %v34 = icmp slt i64 %v33, %v32
  br i1 %v34, label %b8, label %b9

b8:
  %v37 = add i64 %v33, %v21
%ts1.d = load ptr, ptr %v30, !alias.scope !0
%ts1.s = getelementptr inbounds i64, ptr %ts1.d, i64 %v33
store i64 %v37, ptr %ts1.s, !noalias !0
br label %bts1cont

bts1cont:
  %v42 = add i64 0, 1
  %v40 = add i64 %v33, %v42
  br label %b7

b9:
  %v45 = add i64 0, 17
  %v43 = add i64 %v23, %v45
  br label %b10

b10:
  %v46 = phi i64 [ %v43, %b9 ], [ %v50, %b11 ]
  %v48 = add i64 0, 4095
  %v47 = icmp slt i64 %v48, %v46
  br i1 %v47, label %b11, label %b12

b11:
  %v52 = add i64 0, 4096
  %v50 = sub i64 %v46, %v52
  br label %b10

b12:
  %v55 = add i64 0, 41
  %v53 = add i64 %v24, %v55
  br label %b13

b13:
  %v56 = phi i64 [ %v53, %b12 ], [ %v60, %b14 ]
  %v58 = add i64 0, 4095
  %v57 = icmp slt i64 %v58, %v56
  br i1 %v57, label %b14, label %b15

b14:
  %v62 = add i64 0, 4096
  %v60 = sub i64 %v56, %v62
  br label %b13

b15:
  %v65 = add i64 0, 7
  %v63 = add i64 %v25, %v65
  br label %b16

b16:
  %v66 = phi i64 [ %v63, %b15 ], [ %v70, %b17 ]
  %v68 = add i64 0, 63
  %v67 = icmp slt i64 %v68, %v66
  br i1 %v67, label %b17, label %b18

b17:
  %v72 = add i64 0, 64
  %v70 = sub i64 %v66, %v72
  br label %b16

b18:
  call void @glm_tbl_get(ptr %v29, i64 %v46, ptr %ts2.dst)
  %v77 = load i64, ptr %ts2.dst
  %v75 = add i64 %v22, %v77
  call void @glm_tbl_get(ptr %v29, i64 %v56, ptr %ts3.dst)
  %v80 = load i64, ptr %ts3.dst
  %v74 = add i64 %v75, %v80
  call void @glm_tbl_get(ptr %v30, i64 %v66, ptr %ts4.dst)
  %v83 = load i64, ptr %ts4.dst
  %v73 = add i64 %v74, %v83
  call void @glm_tbl_free(ptr %v30)
  %v86 = inttoptr i64 0 to ptr
  %v89 = add i64 0, 1
  %v87 = add i64 %v21, %v89
  br label %b4

b19:
  %v96 = phi i64 [ %v95, %b6 ], [ %v111, %b20 ]
  %v97 = icmp slt i64 %v96, %v94
  br i1 %v97, label %b20, label %b21

b20:
  %v100 = add i64 %v96, %v96
  store i64 %v96, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v92, i64 %v100, ptr %ts5.valp)
  %v110 = add i64 0, 1
  %v108 = add i64 %v96, %v110
  store i64 %v108, ptr %ts6.valp
  call void @glm_tbl_set(ptr %v93, i64 %v100, ptr %ts6.valp)
  %v113 = add i64 0, 1
  %v111 = add i64 %v96, %v113
  br label %b19

b21:
  %v114 = add i64 0, 0
  %v115 = add i64 0, 0
  br label %b22

b22:
  %v116 = phi i64 [ %v114, %b21 ], [ %v121, %b23 ]
  %v117 = phi i64 [ %v115, %b21 ], [ %v134, %b23 ]
  %v118 = icmp slt i64 %v117, %v94
  br i1 %v118, label %b23, label %b24

b23:
  %v126 = add i64 0, 1
  %v124 = add i64 %v117, %v126
  call void @glm_tbl_get(ptr %v92, i64 %v117, ptr %ts7.dst)
  %v128 = load i64, ptr %ts7.dst
  call void @glm_tbl_get(ptr %v93, i64 %v117, ptr %ts8.dst)
  %v131 = load i64, ptr %ts8.dst
  %v127 = add i64 %v128, %v131
  %v123 = mul i64 %v124, %v127
  %v121 = add i64 %v116, %v123
  %v136 = add i64 0, 2
  %v134 = add i64 %v117, %v136
  br label %b22

b24:
  %v137 = getelementptr inbounds [28 x i8], ptr @.str.1, i64 0, i64 0
  call void @glm_print_string(ptr %v137)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v116)
  call void @glm_print_nl()
  %v139 = call ptr @glm_tbl_new(i64 8, i8 1)
  %v141 = add i64 0, 262143999
  %v142 = add i64 0, 123456789
  store i64 %v142, ptr %ts9.valp
  call void @glm_tbl_set(ptr %v139, i64 %v141, ptr %ts9.valp)
  %v143 = getelementptr inbounds [28 x i8], ptr @.str.2, i64 0, i64 0
  %v146 = add i64 0, 262143999
  call void @glm_tbl_get(ptr %v139, i64 %v146, ptr %ts10.dst)
  %v144 = load i64, ptr %ts10.dst
  call void @glm_print_string(ptr %v143)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v144)
  call void @glm_print_nl()
  %v147 = add i64 0, 20000
  %v148 = add i64 0, 0
  %v149 = add i64 0, 0
  br label %b25

b25:
  %v150 = phi i64 [ %v148, %b24 ], [ %v189, %b33 ]
  %v151 = phi i64 [ %v149, %b24 ], [ %v185, %b33 ]
  %v152 = icmp slt i64 %v150, %v147
  br i1 %v152, label %b26, label %b27

b26:
  %v155 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v156 = add i64 0, 0
  %v157 = add i64 0, 128
  call void @glm_tbl_reserve(ptr %v155, i64 %v157)
  br label %b28

b27:
  %v192 = getelementptr inbounds [28 x i8], ptr @.str.3, i64 0, i64 0
  call void @glm_print_string(ptr %v192)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v151)
  call void @glm_print_nl()
  %v194 = add i64 0, 20000
  %v195 = add i64 0, 0
  %v196 = add i64 0, 0
  br label %b34

b28:
  %v158 = phi i64 [ %v156, %b26 ], [ %v167, %bts11cont ]
  %v159 = icmp slt i64 %v158, %v157
  br i1 %v159, label %b29, label %b30

b29:
  %v165 = add i64 0, 3
  %v163 = mul i64 %v158, %v165
  %v162 = add i64 %v163, %v150
%ts11.d = load ptr, ptr %v155, !alias.scope !0
%ts11.s = getelementptr inbounds i64, ptr %ts11.d, i64 %v158
store i64 %v162, ptr %ts11.s, !noalias !0
br label %bts11cont

bts11cont:
  %v169 = add i64 0, 1
  %v167 = add i64 %v158, %v169
  br label %b28

b30:
  %v170 = add i64 0, 0
  %v171 = add i64 0, 0
  br label %b31

b31:
  %v172 = phi i64 [ %v170, %b30 ], [ %v177, %b32 ]
  %v173 = phi i64 [ %v171, %b30 ], [ %v182, %b32 ]
  %v176 = add i64 0, 128
  %v174 = icmp slt i64 %v173, %v176
  br i1 %v174, label %b32, label %b33

b32:
  call void @glm_tbl_get(ptr %v155, i64 %v173, ptr %ts12.dst)
  %v179 = load i64, ptr %ts12.dst
  %v177 = add i64 %v172, %v179
  %v184 = add i64 0, 1
  %v182 = add i64 %v173, %v184
  br label %b31

b33:
  %v185 = add i64 %v151, %v172
  call void @glm_tbl_free(ptr %v155)
  %v188 = inttoptr i64 0 to ptr
  %v191 = add i64 0, 1
  %v189 = add i64 %v150, %v191
  br label %b25

b34:
  %v197 = phi i64 [ %v195, %b27 ], [ %v248, %b42 ]
  %v198 = phi i64 [ %v196, %b27 ], [ %v243, %b42 ]
  %v199 = icmp slt i64 %v197, %v194
  br i1 %v199, label %b35, label %b36

b35:
  %v202 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v203 = add i64 0, 0
  %v204 = add i64 0, 16
  call void @glm_tbl_reserve(ptr %v202, i64 %v204)
  br label %b37

b36:
  %v251 = getelementptr inbounds [28 x i8], ptr @.str.4, i64 0, i64 0
  call void @glm_print_string(ptr %v251)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v198)
  call void @glm_print_nl()
  %v253 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v254 = add i64 0, 262144
  %v255 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v253, i64 %v254)
  br label %b43

b37:
  %v205 = phi i64 [ %v203, %b35 ], [ %v210, %bts13cont ]
  %v206 = icmp slt i64 %v205, %v204
  br i1 %v206, label %b38, label %b39

b38:
%ts13.d = load ptr, ptr %v202, !alias.scope !0
%ts13.s = getelementptr inbounds i64, ptr %ts13.d, i64 %v205
store i64 %v205, ptr %ts13.s, !noalias !0
br label %bts13cont

bts13cont:
  %v212 = add i64 0, 1
  %v210 = add i64 %v205, %v212
  br label %b37

b39:
  %v213 = getelementptr i8, ptr %v202, i64 0
  %v215 = add i64 0, 3
  %v219 = add i64 0, 3
  call void @glm_tbl_get(ptr %v213, i64 %v219, ptr %ts14.dst)
  %v217 = load i64, ptr %ts14.dst
  %v216 = add i64 %v217, %v197
  store i64 %v216, ptr %ts15.valp
  call void @glm_tbl_set(ptr %v213, i64 %v215, ptr %ts15.valp)
  %v222 = add i64 0, 7
  %v226 = add i64 0, 7
  call void @glm_tbl_get(ptr %v202, i64 %v226, ptr %ts16.dst)
  %v224 = load i64, ptr %ts16.dst
  %v223 = add i64 %v224, %v197
  store i64 %v223, ptr %ts17.valp
  call void @glm_tbl_set(ptr %v202, i64 %v222, ptr %ts17.valp)
  %v228 = add i64 0, 0
  %v229 = add i64 0, 0
  br label %b40

b40:
  %v230 = phi i64 [ %v228, %b39 ], [ %v235, %b41 ]
  %v231 = phi i64 [ %v229, %b39 ], [ %v240, %b41 ]
  %v234 = add i64 0, 16
  %v232 = icmp slt i64 %v231, %v234
  br i1 %v232, label %b41, label %b42

b41:
  call void @glm_tbl_get(ptr %v202, i64 %v231, ptr %ts18.dst)
  %v237 = load i64, ptr %ts18.dst
  %v235 = add i64 %v230, %v237
  %v242 = add i64 0, 1
  %v240 = add i64 %v231, %v242
  br label %b40

b42:
  %v243 = add i64 %v198, %v230
  %v246 = inttoptr i64 0 to ptr
  call void @glm_tbl_free(ptr %v202)
  %v247 = inttoptr i64 0 to ptr
  %v250 = add i64 0, 1
  %v248 = add i64 %v197, %v250
  br label %b34

b43:
  %v257 = phi i64 [ %v255, %b36 ], [ %v264, %bts19cont ]
  %v258 = icmp slt i64 %v257, %v254
  br i1 %v258, label %b44, label %b45

b44:
  %v263 = add i64 0, 1
  %v261 = add i64 %v257, %v263
%ts19.d = load ptr, ptr %v253, !alias.scope !0
%ts19.s = getelementptr inbounds i64, ptr %ts19.d, i64 %v257
store i64 %v261, ptr %ts19.s, !noalias !0
br label %bts19cont

bts19cont:
  %v266 = add i64 0, 1
  %v264 = add i64 %v257, %v266
  br label %b43

b45:
  %v267 = add i64 0, 0
  %v268 = add i64 0, 0
  br label %b46

b46:
  %v269 = phi i64 [ %v267, %b45 ], [ %v274, %b47 ]
  %v270 = phi i64 [ %v268, %b45 ], [ %v281, %b47 ]
  %v271 = icmp slt i64 %v270, %v254
  br i1 %v271, label %b47, label %b48

b47:
  call void @glm_tbl_get(ptr %v253, i64 %v270, ptr %ts20.dst)
  %v278 = load i64, ptr %ts20.dst
  %v276 = mul i64 %v270, %v278
  %v274 = add i64 %v269, %v276
  %v283 = add i64 0, 1
  %v281 = add i64 %v270, %v283
  br label %b46

b48:
  %v284 = getelementptr inbounds [28 x i8], ptr @.str.5, i64 0, i64 0
  call void @glm_print_string(ptr %v284)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v269)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
