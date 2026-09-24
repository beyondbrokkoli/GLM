@.str.0 = private unnamed_addr constant [9 x i8] c"negative\00"
@.str.1 = private unnamed_addr constant [5 x i8] c"zero\00"
@.str.2 = private unnamed_addr constant [9 x i8] c"positive\00"
@.str.3 = private unnamed_addr constant [9 x i8] c"negative\00"
@.str.4 = private unnamed_addr constant [5 x i8] c"zero\00"
@.str.5 = private unnamed_addr constant [9 x i8] c"positive\00"
@.str.6 = private unnamed_addr constant [9 x i8] c"negative\00"
@.str.7 = private unnamed_addr constant [5 x i8] c"zero\00"
@.str.8 = private unnamed_addr constant [9 x i8] c"positive\00"
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
  %v1 = add i64 0, 5
  %v0 = sub i64 0, %v1
  %v4 = add i64 0, 0
  %v2 = icmp slt i64 %v0, %v4
  br i1 %v2, label %b1, label %b2

b1:
  %v5 = getelementptr inbounds [9 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v5)
  call void @glm_print_nl()
  br label %b3

b2:
  %v8 = add i64 0, 0
  %v6 = icmp eq i64 %v0, %v8
  br i1 %v6, label %b4, label %b5

b3:
  %v11 = add i64 0, 0
  %v14 = add i64 0, 0
  %v12 = icmp slt i64 %v11, %v14
  br i1 %v12, label %b7, label %b8

b4:
  %v9 = getelementptr inbounds [5 x i8], ptr @.str.1, i64 0, i64 0
  call void @glm_print_string(ptr %v9)
  call void @glm_print_nl()
  br label %b6

b5:
  %v10 = getelementptr inbounds [9 x i8], ptr @.str.2, i64 0, i64 0
  call void @glm_print_string(ptr %v10)
  call void @glm_print_nl()
  br label %b6

b6:
  br label %b3

b7:
  %v15 = getelementptr inbounds [9 x i8], ptr @.str.3, i64 0, i64 0
  call void @glm_print_string(ptr %v15)
  call void @glm_print_nl()
  br label %b9

b8:
  %v18 = add i64 0, 0
  %v16 = icmp eq i64 %v11, %v18
  br i1 %v16, label %b10, label %b11

b9:
  %v21 = add i64 0, 5
  %v24 = add i64 0, 0
  %v22 = icmp slt i64 %v21, %v24
  br i1 %v22, label %b13, label %b14

b10:
  %v19 = getelementptr inbounds [5 x i8], ptr @.str.4, i64 0, i64 0
  call void @glm_print_string(ptr %v19)
  call void @glm_print_nl()
  br label %b12

b11:
  %v20 = getelementptr inbounds [9 x i8], ptr @.str.5, i64 0, i64 0
  call void @glm_print_string(ptr %v20)
  call void @glm_print_nl()
  br label %b12

b12:
  br label %b9

b13:
  %v25 = getelementptr inbounds [9 x i8], ptr @.str.6, i64 0, i64 0
  call void @glm_print_string(ptr %v25)
  call void @glm_print_nl()
  br label %b15

b14:
  %v28 = add i64 0, 0
  %v26 = icmp eq i64 %v21, %v28
  br i1 %v26, label %b16, label %b17

b15:
  %v31 = add i64 0, 0
  %v32 = add i64 0, 10
  br label %b19

b16:
  %v29 = getelementptr inbounds [5 x i8], ptr @.str.7, i64 0, i64 0
  call void @glm_print_string(ptr %v29)
  call void @glm_print_nl()
  br label %b18

b17:
  %v30 = getelementptr inbounds [9 x i8], ptr @.str.8, i64 0, i64 0
  call void @glm_print_string(ptr %v30)
  call void @glm_print_nl()
  br label %b18

b18:
  br label %b15

b19:
  %v33 = phi i64 [ %v31, %b15 ], [ %v43, %b20 ]
  %v34 = phi i64 [ %v32, %b15 ], [ %v46, %b20 ]
  %v38 = add i64 0, 5
  %v36 = icmp slt i64 %v33, %v38
  br i1 %v36, label %b22, label %b23

b20:
  %v45 = add i64 0, 1
  %v43 = add i64 %v33, %v45
  %v48 = add i64 0, 1
  %v46 = sub i64 %v34, %v48
  br label %b19

b21:
  call void @glm_print_int(i64 %v33)
  call void @glm_print_nl()
  call void @glm_print_int(i64 %v34)
  call void @glm_print_nl()
  %v51 = add i64 0, 1
  %v53 = add i64 0, 0
  %v54 = add i64 0, 1
  %v52 = icmp slt i64 %v53, %v54
  br i1 %v52, label %b25, label %b26

b22:
  %v41 = add i64 0, 5
  %v39 = icmp slt i64 %v41, %v34
  br label %b24

b23:
  %v42 = or i1 0, 0
  br label %b24

b24:
  %v35 = phi i1 [ %v39, %b22 ], [ %v42, %b23 ]
  br i1 %v35, label %b20, label %b21

b25:
  %v55 = add i64 0, 100
  call void @glm_print_int(i64 %v55)
  call void @glm_print_nl()
  br label %b27

b26:
  br label %b27

b27:
  call void @glm_print_int(i64 %v51)
  call void @glm_print_nl()
  %v60 = add i64 0, 1
  %v61 = add i64 0, 0
  %v59 = icmp slt i64 %v60, %v61
  %v58 = xor i1 %v59, 1
  call void @glm_print_bool(i1 %v58)
  call void @glm_print_nl()
  ret i32 0
}
