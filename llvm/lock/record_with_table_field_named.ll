@.str.0 = private unnamed_addr constant [7 x i8] c"nested\00"
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
  %ts3.dst = alloca i64
  %ts4.dst = alloca i64
  br label %b0

b0:
  %v1 = add i64 0, 42
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  store i64 %v1, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v5 = getelementptr inbounds [7 x i8], ptr @.str.0, i64 0, i64 0
  %v3 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v6 = add i64 0, 0
  %ts1.cast = ptrtoint ptr %v0 to i64
store i64 %ts1.cast, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v3, i64 %v6, ptr %ts1.valp)
  %v7 = add i64 0, 1
  %ts2.cast = ptrtoint ptr %v5 to i64
store i64 %ts2.cast, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v3, i64 %v7, ptr %ts2.valp)
  %v11 = add i64 0, 0
  call void @glm_tbl_get(ptr %v3, i64 %v11, ptr %ts3.dst)
  %ts3.loaded = load i64, ptr %ts3.dst
%v9 = inttoptr i64 %ts3.loaded to ptr
  %v12 = add i64 0, 0
  call void @glm_tbl_get(ptr %v9, i64 %v12, ptr %ts4.dst)
  %v8 = load i64, ptr %ts4.dst
  call void @glm_print_int(i64 %v8)
  call void @glm_print_nl()
  call void @glm_tbl_free(ptr %v3)
  call void @glm_tbl_free(ptr %v0)
  %v14 = call i64 @sys_alloc_count()
  call void @glm_print_int(i64 %v14)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
