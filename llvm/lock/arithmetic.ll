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
  ret i32 0

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
}
