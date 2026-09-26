declare ptr @glm_tbl_new(i64, i8)
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
  %ts1.valp = alloca i64
  %ts2.dst = alloca i64
  %ts3.dst = alloca i64
  %ts5.valp = alloca i64
  %ts6.valp = alloca i64
  %ts7.valp = alloca i64
  %ts8.dst = alloca i64
  %ts9.dst = alloca i64
  %ts10.dst = alloca i64
  %ts12.valp = alloca i64
  %ts13.dst = alloca i64
  br label %b0

b0:
  %v1 = add i64 0, 1
  %v2 = add i64 0, 2
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  store i64 %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v3, ptr %ts0.valp)
  %v4 = add i64 0, 5
  store i64 %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  %v7 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v7, ptr %ts2.dst)
  %v5 = load i64, ptr %ts2.dst
  %v10 = add i64 0, 5
  call void @glm_tbl_get(ptr %v0, i64 %v10, ptr %ts3.dst)
  %v8 = load i64, ptr %ts3.dst
  %v11 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_int(i64 %v5)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v8)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v11)
  call void @glm_print_nl()
  %v14 = add i64 0, 10
  %v15 = add i64 0, 20
  %v16 = add i64 0, 40
  %v13 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v17 = add i64 0, 0
  store i64 %v14, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v13, i64 %v17, ptr %ts5.valp)
  %v18 = add i64 0, 1
  store i64 %v15, ptr %ts6.valp
  call void @glm_tbl_set(ptr %v13, i64 %v18, ptr %ts6.valp)
  %v19 = add i64 0, 3
  store i64 %v16, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v13, i64 %v19, ptr %ts7.valp)
  %v22 = add i64 0, 0
  call void @glm_tbl_get(ptr %v13, i64 %v22, ptr %ts8.dst)
  %v20 = load i64, ptr %ts8.dst
  %v25 = add i64 0, 1
  call void @glm_tbl_get(ptr %v13, i64 %v25, ptr %ts9.dst)
  %v23 = load i64, ptr %ts9.dst
  %v28 = add i64 0, 3
  call void @glm_tbl_get(ptr %v13, i64 %v28, ptr %ts10.dst)
  %v26 = load i64, ptr %ts10.dst
  %v29 = call i64 @glm_tbl_len(ptr %v13)
  call void @glm_print_int(i64 %v20)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v23)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v26)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v29)
  call void @glm_print_nl()
  %v32 = add i64 0, 9
  %v31 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v33 = add i64 0, 100001
  store i64 %v32, ptr %ts12.valp
  call void @glm_tbl_set(ptr %v31, i64 %v33, ptr %ts12.valp)
  %v36 = add i64 0, 100001
  call void @glm_tbl_get(ptr %v31, i64 %v36, ptr %ts13.dst)
  %v34 = load i64, ptr %ts13.dst
  call void @glm_print_int(i64 %v34)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v31)
  call void @glm_tbl_free(ptr %v13)
  call void @glm_tbl_free(ptr %v0)
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
