declare ptr @glm_tbl_new(i64, i8)
declare void @glm_tbl_free(ptr)
declare void @glm_tbl_get(ptr, i64, ptr)
declare void @glm_tbl_set(ptr, i64, ptr)
declare i64 @sys_alloc_count()
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
  %ts3.valp = alloca i64
  %ts4.valp = alloca ptr
  %ts5.valp = alloca ptr
  %ts6.valp = alloca i64
  %ts7.valp = alloca i64
  %ts8.valp = alloca i64
  %ts9.valp = alloca i64
  %ts10.valp = alloca ptr
  %ts11.valp = alloca ptr
  %ts12.dst = alloca ptr
  %ts13.dst = alloca i64
  %ts14.valp = alloca i64
  br label %b0

b0:
  %v1 = add i64 0, 1
  %v2 = add i64 0, 2
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  store i64 %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v3, ptr %ts0.valp)
  %v4 = add i64 0, 1
  store i64 %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  call void @glm_tbl_free(ptr %v0)
  %v6 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v6)
  call void @glm_print_nl()
  %v9 = add i64 0, 1
  %v8 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v10 = add i64 0, 0
  store i64 %v9, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v8, i64 %v10, ptr %ts2.valp)
  %v12 = add i64 0, 2
  %v11 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v13 = add i64 0, 0
  store i64 %v12, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v11, i64 %v13, ptr %ts3.valp)
  %v7 = call ptr @glm_tbl_new(i64 8, i8 128)
  %v14 = add i64 0, 0
  store ptr %v8, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v7, i64 %v14, ptr %ts4.valp)
  %v15 = add i64 0, 1
  store ptr %v11, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v7, i64 %v15, ptr %ts5.valp)
  call void @glm_tbl_free(ptr %v7)
  %v17 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v17)
  call void @glm_print_nl()
  %v20 = add i64 0, 10
  %v21 = add i64 0, 20
  %v19 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v22 = add i64 0, 0
  store i64 %v20, ptr %ts6.valp
  call void @glm_tbl_set(ptr %v19, i64 %v22, ptr %ts6.valp)
  %v23 = add i64 0, 1
  store i64 %v21, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v19, i64 %v23, ptr %ts7.valp)
  %v25 = add i64 0, 30
  %v26 = add i64 0, 40
  %v24 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v27 = add i64 0, 0
  store i64 %v25, ptr %ts8.valp
  call void @glm_tbl_set(ptr %v24, i64 %v27, ptr %ts8.valp)
  %v28 = add i64 0, 1
  store i64 %v26, ptr %ts9.valp
  call void @glm_tbl_set(ptr %v24, i64 %v28, ptr %ts9.valp)
  %v18 = call ptr @glm_tbl_new(i64 8, i8 128)
  %v29 = add i64 0, 0
  store ptr %v19, ptr %ts10.valp
  call void @glm_tbl_set(ptr %v18, i64 %v29, ptr %ts10.valp)
  %v30 = add i64 0, 1
  store ptr %v24, ptr %ts11.valp
  call void @glm_tbl_set(ptr %v18, i64 %v30, ptr %ts11.valp)
  %v34 = add i64 0, 0
  call void @glm_tbl_get(ptr %v18, i64 %v34, ptr %ts12.dst)
  %v32 = load ptr, ptr %ts12.dst
  %v35 = add i64 0, 1
  call void @glm_tbl_get(ptr %v32, i64 %v35, ptr %ts13.dst)
  %v31 = load i64, ptr %ts13.dst
  call void @glm_print_int(i64 %v31)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v18)
  %v37 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v37)
  call void @glm_print_nl()
  %v39 = add i64 0, 1
  %v38 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v40 = add i64 0, 0
  store i64 %v39, ptr %ts14.valp
  call void @glm_tbl_set(ptr %v38, i64 %v40, ptr %ts14.valp)
  call void @glm_tbl_free(ptr %v38)
  %v41 = inttoptr i64 0 to ptr
  %v43 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v43)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
