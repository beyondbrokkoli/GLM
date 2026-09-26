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
  %ts2.valp = alloca ptr
  %ts3.dst = alloca ptr
  %ts4.dst = alloca i64
  %ts5.dst = alloca ptr
  %ts6.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v4 = add i64 0, 7
  %v5 = add i64 0, 8
  %v3 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v6 = add i64 0, 0
  store i64 %v4, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v3, i64 %v6, ptr %ts0.valp)
  %v7 = add i64 0, 1
  store i64 %v5, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v3, i64 %v7, ptr %ts1.valp)
  store ptr %v3, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts2.valp)
  %v11 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v11, ptr %ts3.dst)
  %v9 = load ptr, ptr %ts3.dst
  %v12 = add i64 0, 0
  call void @glm_tbl_get(ptr %v9, i64 %v12, ptr %ts4.dst)
  %v8 = load i64, ptr %ts4.dst
  %v16 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v16, ptr %ts5.dst)
  %v14 = load ptr, ptr %ts5.dst
  %v17 = add i64 0, 1
  call void @glm_tbl_get(ptr %v14, i64 %v17, ptr %ts6.dst)
  %v13 = load i64, ptr %ts6.dst
  call void @glm_print_int(i64 %v8)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v13)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v0)
  %v19 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v19)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
