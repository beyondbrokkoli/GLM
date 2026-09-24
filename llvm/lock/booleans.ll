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
  %v2 = or i1 0, 1
  br i1 %v2, label %b1, label %b2

b1:
  %v3 = or i1 0, 0
  br label %b3

b2:
  %v4 = or i1 0, 0
  br label %b3

b3:
  %v1 = phi i1 [ %v3, %b1 ], [ %v4, %b2 ]
  br i1 %v1, label %b4, label %b5

b4:
  %v6 = or i1 0, 1
  br label %b6

b5:
  %v5 = or i1 0, 1
  br label %b6

b6:
  %v0 = phi i1 [ %v6, %b4 ], [ %v5, %b5 ]
  call void @glm_print_bool(i1 %v0)
  call void @glm_print_nl()
  %v9 = add i64 0, 1
  %v10 = add i64 0, 2
  %v8 = icmp slt i64 %v9, %v10
  br i1 %v8, label %b7, label %b8

b7:
  %v12 = add i64 0, 2
  %v13 = add i64 0, 1
  %v11 = icmp slt i64 %v12, %v13
  br label %b9

b8:
  %v14 = or i1 0, 0
  br label %b9

b9:
  %v7 = phi i1 [ %v11, %b7 ], [ %v14, %b8 ]
  call void @glm_print_bool(i1 %v7)
  call void @glm_print_nl()
  %v17 = add i64 0, 3
  %v18 = add i64 0, 4
  %v16 = icmp eq i64 %v17, %v18
  %v15 = xor i1 %v16, 1
  call void @glm_print_bool(i1 %v15)
  call void @glm_print_nl()
  %v21 = or i1 0, 1
  %v22 = or i1 0, 0
  %v20 = icmp eq i1 %v21, %v22
  call void @glm_print_bool(i1 %v20)
  call void @glm_print_nl()
  %v23 = or i1 0, 1
  %v24 = add i64 0, 0
  br label %b10

b10:
  %v25 = phi i1 [ %v23, %b9 ], [ %v34, %b15 ]
  %v26 = phi i64 [ %v24, %b9 ], [ %v35, %b15 ]
  %v29 = add i64 0, 4
  %v27 = icmp slt i64 %v26, %v29
  br i1 %v27, label %b11, label %b12

b11:
  %v32 = add i64 0, 2
  %v30 = icmp eq i64 %v26, %v32
  br i1 %v30, label %b13, label %b14

b12:
  call void @glm_print_bool(i1 %v25)
  call void @glm_print_nl()
  ret i32 0

b13:
  %v33 = or i1 0, 0
  br label %b15

b14:
  br label %b15

b15:
  %v34 = phi i1 [ %v33, %b13 ], [ %v25, %b14 ]
  %v37 = add i64 0, 1
  %v35 = add i64 %v26, %v37
  br label %b10
}
