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
  %ts0.valp = alloca i8
  %ts1.valp = alloca i8
  %ts2.dst = alloca i8
  %ts3.dst = alloca i8
  %ts4.dst = alloca i8
  %ts6.dst = alloca i8
  %ts7.valp = alloca i8
  %ts8.dst = alloca i8
  %ts9.dst = alloca i8
  br label %b0

b0:
  %v1 = or i1 0, 1
  %v2 = or i1 0, 0
  %v0 = call ptr @glm_tbl_new(i64 1, i8 0)
  %v3 = add i64 0, 0
  %ts0.z = zext i1 %v1 to i8
store i8 %ts0.z, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v3, ptr %ts0.valp)
  %v4 = add i64 0, 1
  %ts1.z = zext i1 %v2 to i8
store i8 %ts1.z, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  %v7 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v7, ptr %ts2.dst)
  %ts2.c = load i8, ptr %ts2.dst
%v5 = icmp ne i8 %ts2.c, 0
  %v10 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v10, ptr %ts3.dst)
  %ts3.c = load i8, ptr %ts3.dst
%v8 = icmp ne i8 %ts3.c, 0
  %v13 = add i64 0, 2
  call void @glm_tbl_get(ptr %v0, i64 %v13, ptr %ts4.dst)
  %ts4.c = load i8, ptr %ts4.dst
%v11 = icmp ne i8 %ts4.c, 0
  %v14 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_bool(i1 %v5)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v8)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v11)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v14)
  call void @glm_print_nl()
  %v16 = add i64 0, 0
  %v17 = add i64 0, 5
  call void @glm_tbl_reserve(ptr %v0, i64 %v17)
  br label %b1

b1:
  %v18 = phi i64 [ %v16, %b0 ], [ %v26, %bts7cont ]
  %v19 = icmp slt i64 %v18, %v17
  br i1 %v19, label %b2, label %b3

b2:
  call void @glm_tbl_get(ptr %v0, i64 %v18, ptr %ts6.dst)
  %ts6.c = load i8, ptr %ts6.dst
%v23 = icmp ne i8 %ts6.c, 0
  %v22 = xor i1 %v23, 1
  %ts7.c = zext i1 %v22 to i8
%ts7.d = load ptr, ptr %v0, !alias.scope !0
%ts7.s = getelementptr inbounds i8, ptr %ts7.d, i64 %v18
store i8 %ts7.c, ptr %ts7.s, !noalias !0
br label %bts7cont

bts7cont:
  %v28 = add i64 0, 1
  %v26 = add i64 %v18, %v28
  br label %b1

b3:
  %v31 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v31, ptr %ts8.dst)
  %ts8.c = load i8, ptr %ts8.dst
%v29 = icmp ne i8 %ts8.c, 0
  %v34 = add i64 0, 3
  call void @glm_tbl_get(ptr %v0, i64 %v34, ptr %ts9.dst)
  %ts9.c = load i8, ptr %ts9.dst
%v32 = icmp ne i8 %ts9.c, 0
  call void @glm_print_bool(i1 %v29)
  call void @glm_print_sep()
  call void @glm_print_bool(i1 %v32)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
