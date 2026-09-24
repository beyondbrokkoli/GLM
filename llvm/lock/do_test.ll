declare ptr @glm_tbl_new(i64, i8)
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
  %ts2.valp = alloca i64
  %ts3.dst = alloca i64
  %ts4.valp = alloca i64
  %ts5.valp = alloca i64
  %ts6.valp = alloca i64
  %ts7.valp = alloca i64
  %ts8.valp = alloca i64
  %ts9.dst = alloca i64
  %ts10.dst = alloca i64
  br label %b0

b0:
  %v1 = add i64 0, 1
  %v2 = add i64 0, 2
  %v3 = add i64 0, 3
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v4 = add i64 0, 0
  store i64 %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts0.valp)
  %v5 = add i64 0, 1
  store i64 %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v5, ptr %ts1.valp)
  %v6 = add i64 0, 2
  store i64 %v3, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v0, i64 %v6, ptr %ts2.valp)
  %v9 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v9, ptr %ts3.dst)
  %v7 = load i64, ptr %ts3.dst
  call void @glm_print_int(i64 %v7)
  call void @glm_print_nl()
  %v11 = add i64 0, 10
  %v12 = add i64 0, 20
  %v13 = add i64 0, 30
  %v14 = add i64 0, 40
  %v15 = add i64 0, 50
  %v10 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v16 = add i64 0, 0
  store i64 %v11, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v10, i64 %v16, ptr %ts4.valp)
  %v17 = add i64 0, 1
  store i64 %v12, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v10, i64 %v17, ptr %ts5.valp)
  %v18 = add i64 0, 2
  store i64 %v13, ptr %ts6.valp
  call void @glm_tbl_set(ptr %v10, i64 %v18, ptr %ts6.valp)
  %v19 = add i64 0, 3
  store i64 %v14, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v10, i64 %v19, ptr %ts7.valp)
  %v20 = add i64 0, 4
  store i64 %v15, ptr %ts8.valp
  call void @glm_tbl_set(ptr %v10, i64 %v20, ptr %ts8.valp)
  %v23 = add i64 0, 0
  call void @glm_tbl_get(ptr %v10, i64 %v23, ptr %ts9.dst)
  %v21 = load i64, ptr %ts9.dst
  call void @glm_print_int(i64 %v21)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v10)
  %v26 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v26, ptr %ts10.dst)
  %v24 = load i64, ptr %ts10.dst
  call void @glm_print_int(i64 %v24)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
