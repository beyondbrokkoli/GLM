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
  %ts0.valp = alloca i64
  %ts1.dst = alloca i64
  %ts2.dst = alloca i64
  %ts3.dst = alloca i64
  %ts4.dst = alloca i64
  %ts5.valp = alloca i64
  %ts6.valp = alloca i64
  %ts7.dst = alloca i64
  %ts8.valp = alloca i64
  %ts9.dst = alloca i64
  %ts10.valp = alloca i64
  %ts11.valp = alloca i64
  %ts12.dst = alloca i64
  %ts13.dst = alloca i64
  %ts14.dst = alloca i64
  %ts15.valp = alloca i64
  %ts16.dst = alloca i64
  %ts18.dst = alloca i64
  %ts19.dst = alloca i64
  %ts20.dst = alloca i64
  %ts21.valp = alloca i64
  %ts22.dst = alloca i64
  %ts23.valp = alloca i64
  %ts24.dst = alloca i64
  %ts25.valp = alloca i64
  %ts26.dst = alloca i64
  %ts27.dst = alloca i64
  %ts28.dst = alloca i64
  %ts29.valp = alloca i64
  %ts30.dst = alloca i64
  %ts31.valp = alloca i64
  %ts32.dst = alloca i64
  %ts34.valp = alloca i64
  %ts35.valp = alloca i64
  %ts36.dst = alloca i64
  %ts37.dst = alloca i64
  %ts38.dst = alloca i64
  %ts39.valp = alloca i64
  %ts40.valp = alloca i64
  %ts41.valp = alloca i64
  %ts42.dst = alloca i64
  %ts44.valp = alloca i64
  %ts45.valp = alloca i64
  %ts46.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v1 = add i64 0, 4000000
  %v2 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v0, i64 %v1)
  br label %b1

b1:
  %v4 = phi i64 [ %v2, %b0 ], [ %v11, %bts0cont ]
  %v5 = icmp slt i64 %v4, %v1
  br i1 %v5, label %b2, label %b3

b2:
  %v10 = add i64 0, 1
  %v8 = add i64 %v4, %v10
%ts0.d = load ptr, ptr %v0, !alias.scope !0
%ts0.s = getelementptr inbounds i64, ptr %ts0.d, i64 %v4
store i64 %v8, ptr %ts0.s, !noalias !0
br label %bts0cont

bts0cont:
  %v13 = add i64 0, 2
  %v11 = add i64 %v4, %v13
  br label %b1

b3:
  %v14 = add i64 0, 0
  %v15 = add i64 0, 0
  br label %b4

b4:
  %v16 = phi i64 [ %v14, %b3 ], [ %v21, %b5 ]
  %v17 = phi i64 [ %v15, %b3 ], [ %v28, %b5 ]
  %v18 = icmp slt i64 %v17, %v1
  br i1 %v18, label %b5, label %b6

b5:
  call void @glm_tbl_get(ptr %v0, i64 %v17, ptr %ts1.dst)
  %v25 = load i64, ptr %ts1.dst
  %v23 = mul i64 %v17, %v25
  %v21 = add i64 %v16, %v23
  %v30 = add i64 0, 1
  %v28 = add i64 %v17, %v30
  br label %b4

b6:
  %v34 = add i64 0, 3999998
  call void @glm_tbl_get(ptr %v0, i64 %v34, ptr %ts2.dst)
  %v32 = load i64, ptr %ts2.dst
  call void @glm_print_int(i64 %v1)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v32)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v16)
  call void @glm_print_nl()
  %v36 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v37 = add i64 0, 100
  %v38 = add i64 0, 0
  br label %b7

b7:
  %v39 = phi i64 [ %v38, %b6 ], [ %v55, %b12 ]
  %v40 = icmp slt i64 %v39, %v37
  br i1 %v40, label %b8, label %b9

b8:
  %v43 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v36, i64 %v39)
  br label %b10

b9:
  %v60 = add i64 0, 44
  call void @glm_tbl_get(ptr %v36, i64 %v60, ptr %ts3.dst)
  %v58 = load i64, ptr %ts3.dst
  %v63 = add i64 0, 49
  call void @glm_tbl_get(ptr %v36, i64 %v63, ptr %ts4.dst)
  %v61 = load i64, ptr %ts4.dst
  call void @glm_print_int(i64 %v58)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v61)
  call void @glm_print_nl()
  %v64 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v65 = add i64 0, 2500000
  %v66 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v64, i64 %v65)
  br label %b13

b10:
  %v45 = phi i64 [ %v43, %b8 ], [ %v52, %bts5cont ]
  %v46 = icmp slt i64 %v45, %v39
  br i1 %v46, label %b11, label %b12

b11:
  %v51 = add i64 0, 1
  %v49 = add i64 %v45, %v51
%ts5.d = load ptr, ptr %v36, !alias.scope !0
%ts5.s = getelementptr inbounds i64, ptr %ts5.d, i64 %v45
store i64 %v49, ptr %ts5.s, !noalias !0
br label %bts5cont

bts5cont:
  %v54 = add i64 0, 1
  %v52 = add i64 %v45, %v54
  br label %b10

b12:
  %v57 = add i64 0, 1
  %v55 = add i64 %v39, %v57
  br label %b7

b13:
  %v68 = phi i64 [ %v66, %b9 ], [ %v73, %bts6cont ]
  %v69 = icmp slt i64 %v68, %v65
  br i1 %v69, label %b14, label %b15

b14:
  %v72 = add i64 0, 5
%ts6.d = load ptr, ptr %v64, !alias.scope !0
%ts6.s = getelementptr inbounds i64, ptr %ts6.d, i64 %v68
store i64 %v72, ptr %ts6.s, !noalias !0
br label %bts6cont

bts6cont:
  %v75 = add i64 0, 1
  %v73 = add i64 %v68, %v75
  br label %b13

b15:
  %v76 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v64, i64 %v65)
  br label %b16

b16:
  %v78 = phi i64 [ %v76, %b15 ], [ %v87, %bts8cont ]
  %v79 = icmp slt i64 %v78, %v65
  br i1 %v79, label %b17, label %b18

b17:
  call void @glm_tbl_get(ptr %v64, i64 %v78, ptr %ts7.dst)
  %v83 = load i64, ptr %ts7.dst
  %v86 = add i64 0, 1
  %v82 = add i64 %v83, %v86
%ts8.d = load ptr, ptr %v64, !alias.scope !0
%ts8.s = getelementptr inbounds i64, ptr %ts8.d, i64 %v78
store i64 %v82, ptr %ts8.s, !noalias !0
br label %bts8cont

bts8cont:
  %v89 = add i64 0, 1
  %v87 = add i64 %v78, %v89
  br label %b16

b18:
  %v90 = add i64 0, 0
  %v91 = add i64 0, 0
  br label %b19

b19:
  %v92 = phi i64 [ %v90, %b18 ], [ %v97, %b20 ]
  %v93 = phi i64 [ %v91, %b18 ], [ %v104, %b20 ]
  %v96 = add i64 0, 10
  %v94 = icmp slt i64 %v93, %v96
  br i1 %v94, label %b20, label %b21

b20:
  %v100 = add i64 0, 10
  %v98 = mul i64 %v92, %v100
  call void @glm_tbl_get(ptr %v64, i64 %v93, ptr %ts9.dst)
  %v101 = load i64, ptr %ts9.dst
  %v97 = add i64 %v98, %v101
  %v106 = add i64 0, 1
  %v104 = add i64 %v93, %v106
  br label %b19

b21:
  %v109 = add i64 0, 1
  %v107 = sub i64 %v65, %v109
  call void @glm_print_int(i64 %v107)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v92)
  call void @glm_print_nl()
  %v111 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v112 = add i64 0, 0
  %v113 = add i64 0, 30000
  call void @glm_tbl_reserve(ptr %v111, i64 %v113)
  br label %b22

b22:
  %v114 = phi i64 [ %v112, %b21 ], [ %v119, %bts10cont ]
  %v115 = icmp slt i64 %v114, %v113
  br i1 %v115, label %b23, label %b24

b23:
  %v118 = add i64 0, 1
%ts10.d = load ptr, ptr %v111, !alias.scope !0
%ts10.s = getelementptr inbounds i64, ptr %ts10.d, i64 %v114
store i64 %v118, ptr %ts10.s, !noalias !0
br label %bts10cont

bts10cont:
  %v121 = add i64 0, 1
  %v119 = add i64 %v114, %v121
  br label %b22

b24:
  %v123 = add i64 0, 30
  %v124 = add i64 0, 60
  store i64 %v124, ptr %ts11.valp
  call void @glm_tbl_set(ptr %v111, i64 %v123, ptr %ts11.valp)
  %v125 = add i64 0, 60
  %v126 = add i64 0, 0
  br label %b25

b25:
  %v127 = phi i64 [ %v126, %b24 ], [ %v133, %b26 ]
  call void @glm_tbl_get(ptr %v111, i64 %v127, ptr %ts12.dst)
  %v129 = load i64, ptr %ts12.dst
  %v128 = icmp slt i64 %v129, %v125
  br i1 %v128, label %b26, label %b27

b26:
  %v135 = add i64 0, 1
  %v133 = add i64 %v127, %v135
  br label %b25

b27:
  %v138 = add i64 0, 0
  call void @glm_tbl_get(ptr %v111, i64 %v138, ptr %ts13.dst)
  %v136 = load i64, ptr %ts13.dst
  %v142 = add i64 0, 30
  call void @glm_tbl_get(ptr %v111, i64 %v142, ptr %ts14.dst)
  %v140 = load i64, ptr %ts14.dst
  call void @glm_print_int(i64 %v136)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v127)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v140)
  call void @glm_print_nl()
  %v143 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v144 = add i64 0, 200000
  %v145 = add i64 0, 3
  %v146 = add i64 0, 0
  br label %b28

b28:
  %v147 = phi i64 [ %v146, %b27 ], [ %v163, %b33 ]
  %v148 = icmp slt i64 %v147, %v144
  br i1 %v148, label %b29, label %b30

b29:
  %v151 = add i64 %v147, 0
  %v152 = add i64 0, 0
  br label %b31

b30:
  %v166 = add i64 0, 0
  %v167 = add i64 0, 0
  br label %b34

b31:
  %v153 = phi i64 [ %v152, %b29 ], [ %v160, %b32 ]
  %v154 = icmp slt i64 %v153, %v145
  br i1 %v154, label %b32, label %b33

b32:
  %v159 = add i64 0, 7
  store i64 %v159, ptr %ts15.valp
  call void @glm_tbl_set(ptr %v143, i64 %v151, ptr %ts15.valp)
  %v162 = add i64 0, 1
  %v160 = add i64 %v153, %v162
  br label %b31

b33:
  %v165 = add i64 0, 1
  %v163 = add i64 %v147, %v165
  br label %b28

b34:
  %v168 = phi i64 [ %v166, %b30 ], [ %v173, %b35 ]
  %v169 = phi i64 [ %v167, %b30 ], [ %v180, %b35 ]
  %v172 = add i64 0, 3
  %v170 = icmp slt i64 %v169, %v172
  br i1 %v170, label %b35, label %b36

b35:
  %v176 = add i64 0, 10
  %v174 = mul i64 %v168, %v176
  call void @glm_tbl_get(ptr %v143, i64 %v169, ptr %ts16.dst)
  %v177 = load i64, ptr %ts16.dst
  %v173 = add i64 %v174, %v177
  %v182 = add i64 0, 1
  %v180 = add i64 %v169, %v182
  br label %b34

b36:
  %v183 = call i64 @glm_tbl_len(ptr %v143)
  %v187 = add i64 0, 2
  call void @glm_tbl_get(ptr %v143, i64 %v187, ptr %ts18.dst)
  %v185 = load i64, ptr %ts18.dst
  call void @glm_print_int(i64 %v183)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v185)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v168)
  call void @glm_print_nl()
  %v189 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v190 = add i64 0, 60000
  %v191 = add i64 0, 0
  br label %b37

b37:
  %v192 = phi i64 [ %v191, %b36 ], [ %v208, %b42 ]
  %v193 = icmp slt i64 %v192, %v190
  br i1 %v193, label %b38, label %b39

b38:
  %v196 = add i64 %v192, 0
  call void @glm_tbl_reserve(ptr %v189, i64 %v190)
  br label %b40

b39:
  %v213 = add i64 0, 59999
  call void @glm_tbl_get(ptr %v189, i64 %v213, ptr %ts19.dst)
  %v211 = load i64, ptr %ts19.dst
  %v216 = add i64 0, 59998
  call void @glm_tbl_get(ptr %v189, i64 %v216, ptr %ts20.dst)
  %v214 = load i64, ptr %ts20.dst
  call void @glm_print_int(i64 %v211)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v214)
  call void @glm_print_nl()
  %v217 = add i64 0, 0
  %v218 = add i64 0, 0
  br label %b43

b40:
  %v198 = phi i64 [ %v196, %b38 ], [ %v205, %bts21cont ]
  %v199 = icmp slt i64 %v198, %v190
  br i1 %v199, label %b41, label %b42

b41:
  %v204 = add i64 0, 1
  %v202 = add i64 %v198, %v204
%ts21.d = load ptr, ptr %v189, !alias.scope !0
%ts21.s = getelementptr inbounds i64, ptr %ts21.d, i64 %v198
store i64 %v202, ptr %ts21.s, !noalias !0
br label %bts21cont

bts21cont:
  %v207 = add i64 0, 1
  %v205 = add i64 %v198, %v207
  br label %b40

b42:
  %v210 = add i64 0, 1
  %v208 = add i64 %v192, %v210
  br label %b37

b43:
  %v219 = phi i64 [ %v217, %b39 ], [ %v224, %b44 ]
  %v220 = phi i64 [ %v218, %b39 ], [ %v229, %b44 ]
  %v221 = icmp slt i64 %v220, %v190
  br i1 %v221, label %b44, label %b45

b44:
  call void @glm_tbl_get(ptr %v189, i64 %v220, ptr %ts22.dst)
  %v226 = load i64, ptr %ts22.dst
  %v224 = add i64 %v219, %v226
  %v231 = add i64 0, 1
  %v229 = add i64 %v220, %v231
  br label %b43

b45:
  call void @glm_print_int(i64 %v190)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v219)
  call void @glm_print_nl()
  %v234 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v235 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v236 = add i64 0, 180
  %v237 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v234, i64 %v236)
  br label %b46

b46:
  %v239 = phi i64 [ %v237, %b45 ], [ %v246, %bts23cont ]
  %v240 = icmp slt i64 %v239, %v236
  br i1 %v240, label %b47, label %b48

b47:
  %v245 = add i64 0, 1
  %v243 = add i64 %v239, %v245
%ts23.d = load ptr, ptr %v234, !alias.scope !0
%ts23.s = getelementptr inbounds i64, ptr %ts23.d, i64 %v239
store i64 %v243, ptr %ts23.s, !noalias !0
br label %bts23cont

bts23cont:
  %v248 = add i64 0, 1
  %v246 = add i64 %v239, %v248
  br label %b46

b48:
  %v249 = add i64 0, 0
  br label %b49

b49:
  %v250 = phi i64 [ %v249, %b48 ], [ %v264, %b50 ]
  %v251 = icmp slt i64 %v250, %v236
  br i1 %v251, label %b50, label %b51

b50:
  %v257 = add i64 0, 1
  %v255 = sub i64 %v236, %v257
  %v254 = sub i64 %v255, %v250
  call void @glm_tbl_get(ptr %v234, i64 %v250, ptr %ts24.dst)
  %v261 = load i64, ptr %ts24.dst
  store i64 %v261, ptr %ts25.valp
  call void @glm_tbl_set(ptr %v235, i64 %v254, ptr %ts25.valp)
  %v266 = add i64 0, 1
  %v264 = add i64 %v250, %v266
  br label %b49

b51:
  %v269 = add i64 0, 0
  call void @glm_tbl_get(ptr %v235, i64 %v269, ptr %ts26.dst)
  %v267 = load i64, ptr %ts26.dst
  %v272 = add i64 0, 44
  call void @glm_tbl_get(ptr %v235, i64 %v272, ptr %ts27.dst)
  %v270 = load i64, ptr %ts27.dst
  %v275 = add i64 0, 89
  call void @glm_tbl_get(ptr %v235, i64 %v275, ptr %ts28.dst)
  %v273 = load i64, ptr %ts28.dst
  call void @glm_print_int(i64 %v267)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v270)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v273)
  call void @glm_print_nl()
  %v276 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v277 = add i64 0, 250
  %v278 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v276, i64 %v277)
  br label %b52

b52:
  %v280 = phi i64 [ %v278, %b51 ], [ %v287, %bts29cont ]
  %v281 = icmp slt i64 %v280, %v277
  br i1 %v281, label %b53, label %b54

b53:
  %v286 = add i64 0, 1
  %v284 = add i64 %v280, %v286
%ts29.d = load ptr, ptr %v276, !alias.scope !0
%ts29.s = getelementptr inbounds i64, ptr %ts29.d, i64 %v280
store i64 %v284, ptr %ts29.s, !noalias !0
br label %bts29cont

bts29cont:
  %v289 = add i64 0, 1
  %v287 = add i64 %v280, %v289
  br label %b52

b54:
  %v290 = add i64 0, 0
  %v291 = add i64 0, 0
  br label %b55

b55:
  %v292 = phi i64 [ %v290, %b54 ], [ %v297, %b56 ]
  %v293 = phi i64 [ %v291, %b54 ], [ %v302, %b56 ]
  %v294 = icmp slt i64 %v293, %v277
  br i1 %v294, label %b56, label %b57

b56:
  call void @glm_tbl_get(ptr %v276, i64 %v293, ptr %ts30.dst)
  %v299 = load i64, ptr %ts30.dst
  %v297 = add i64 %v292, %v299
  %v304 = add i64 0, 1
  %v302 = add i64 %v293, %v304
  br label %b55

b57:
  call void @glm_print_int(i64 %v277)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v292)
  call void @glm_print_nl()
  %v307 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v309 = add i64 0, 0
  %v310 = add i64 0, 1
  %v308 = icmp slt i64 %v309, %v310
  %v311 = add i64 0, 0
  br label %b58

b58:
  %v312 = phi i1 [ %v308, %b57 ], [ %v318, %b59 ]
  %v313 = phi i64 [ %v311, %b57 ], [ %v321, %b59 ]
  br i1 %v312, label %b59, label %b60

b59:
  %v317 = add i64 0, 100
  store i64 %v317, ptr %ts31.valp
  call void @glm_tbl_set(ptr %v307, i64 %v313, ptr %ts31.valp)
  %v319 = add i64 0, 0
  %v320 = add i64 0, 0
  %v318 = icmp slt i64 %v319, %v320
  %v323 = add i64 0, 1
  %v321 = add i64 %v313, %v323
  br label %b58

b60:
  %v326 = add i64 0, 0
  call void @glm_tbl_get(ptr %v307, i64 %v326, ptr %ts32.dst)
  %v324 = load i64, ptr %ts32.dst
  %v327 = call i64 @glm_tbl_len(ptr %v307)
  call void @glm_print_int(i64 %v324)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v327)
  call void @glm_print_nl()
  %v329 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v330 = add i64 0, 100
  %v331 = add i64 0, 150
  call void @glm_tbl_reserve(ptr %v329, i64 %v331)
  br label %b61

b61:
  %v332 = phi i64 [ %v330, %b60 ], [ %v339, %bts34cont ]
  %v333 = icmp slt i64 %v332, %v331
  br i1 %v333, label %b62, label %b63

b62:
  %v338 = add i64 0, 100
  %v336 = sub i64 %v332, %v338
%ts34.d = load ptr, ptr %v329, !alias.scope !0
%ts34.s = getelementptr inbounds i64, ptr %ts34.d, i64 %v332
store i64 %v336, ptr %ts34.s, !noalias !0
br label %bts34cont

bts34cont:
  %v341 = add i64 0, 1
  %v339 = add i64 %v332, %v341
  br label %b61

b63:
  %v342 = add i64 0, 150
  %v343 = add i64 0, 200
  call void @glm_tbl_reserve(ptr %v329, i64 %v343)
  br label %b64

b64:
  %v344 = phi i64 [ %v342, %b63 ], [ %v349, %bts35cont ]
  %v345 = icmp slt i64 %v344, %v343
  br i1 %v345, label %b65, label %b66

b65:
%ts35.d = load ptr, ptr %v329, !alias.scope !0
%ts35.s = getelementptr inbounds i64, ptr %ts35.d, i64 %v344
store i64 %v344, ptr %ts35.s, !noalias !0
br label %bts35cont

bts35cont:
  %v351 = add i64 0, 1
  %v349 = add i64 %v344, %v351
  br label %b64

b66:
  %v354 = add i64 0, 149
  call void @glm_tbl_get(ptr %v329, i64 %v354, ptr %ts36.dst)
  %v352 = load i64, ptr %ts36.dst
  %v357 = add i64 0, 150
  call void @glm_tbl_get(ptr %v329, i64 %v357, ptr %ts37.dst)
  %v355 = load i64, ptr %ts37.dst
  %v360 = add i64 0, 99
  call void @glm_tbl_get(ptr %v329, i64 %v360, ptr %ts38.dst)
  %v358 = load i64, ptr %ts38.dst
  call void @glm_print_int(i64 %v352)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v355)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v358)
  call void @glm_print_nl()
  %v361 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v362 = add i64 0, 8
  %v363 = add i64 0, 0
  br label %b67

b67:
  %v364 = phi i64 [ %v363, %b66 ], [ %v383, %b68 ]
  %v365 = icmp slt i64 %v364, %v362
  br i1 %v365, label %b68, label %b69

b68:
  %v368 = add i64 %v364, 0
  %v371 = add i64 0, 1
  store i64 %v371, ptr %ts39.valp
  call void @glm_tbl_set(ptr %v361, i64 %v368, ptr %ts39.valp)
  %v372 = add i64 %v368, 0
  %v375 = add i64 0, 0
  %v373 = add i64 %v372, %v375
  %v378 = add i64 0, 2
  store i64 %v378, ptr %ts40.valp
  call void @glm_tbl_set(ptr %v361, i64 %v373, ptr %ts40.valp)
  %v379 = add i64 %v364, 0
  %v382 = add i64 0, 3
  store i64 %v382, ptr %ts41.valp
  call void @glm_tbl_set(ptr %v361, i64 %v379, ptr %ts41.valp)
  %v385 = add i64 0, 1
  %v383 = add i64 %v364, %v385
  br label %b67

b69:
  %v388 = add i64 0, 7
  call void @glm_tbl_get(ptr %v361, i64 %v388, ptr %ts42.dst)
  %v386 = load i64, ptr %ts42.dst
  %v390 = call i64 @glm_tbl_len(ptr %v361)
  call void @glm_print_int(i64 %v386)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v362)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v390)
  call void @glm_print_nl()
  %v392 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v393 = getelementptr i8, ptr %v392, i64 0
  %v394 = add i64 0, 8
  %v395 = add i64 0, 0
  call void @glm_tbl_reserve(ptr %v392, i64 %v394)
  call void @glm_tbl_reserve(ptr %v393, i64 %v394)
  br label %b70

b70:
  %v397 = phi i64 [ %v395, %b69 ], [ %v409, %bts45cont ]
  %v398 = icmp slt i64 %v397, %v394
  br i1 %v398, label %b71, label %b72

b71:
  %v403 = add i64 0, 1
  %v401 = add i64 %v397, %v403
%ts44.d = load ptr, ptr %v392, !alias.scope !0
%ts44.s = getelementptr inbounds i64, ptr %ts44.d, i64 %v397
store i64 %v401, ptr %ts44.s, !noalias !0
br label %bts44cont

bts44cont:
  %v408 = add i64 0, 2
  %v406 = add i64 %v397, %v408
%ts45.d = load ptr, ptr %v393, !alias.scope !0
%ts45.s = getelementptr inbounds i64, ptr %ts45.d, i64 %v397
store i64 %v406, ptr %ts45.s, !noalias !0
br label %bts45cont

bts45cont:
  %v411 = add i64 0, 1
  %v409 = add i64 %v397, %v411
  br label %b70

b72:
  %v414 = add i64 0, 3
  call void @glm_tbl_get(ptr %v393, i64 %v414, ptr %ts46.dst)
  %v412 = load i64, ptr %ts46.dst
  %v415 = call i64 @glm_tbl_len(ptr %v392)
  %v417 = call i64 @glm_tbl_len(ptr %v393)
  call void @glm_print_int(i64 %v412)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v415)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v417)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
