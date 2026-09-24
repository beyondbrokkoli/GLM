@.str.0 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"world\00"
declare ptr @glm_tbl_new(i64, i8)
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
  %ts0.valp = alloca ptr
  %ts1.valp = alloca ptr
  %ts2.dst = alloca ptr
  %ts3.dst = alloca ptr
  %ts5.dst = alloca ptr
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v3 = getelementptr inbounds [6 x i8], ptr @.str.0, i64 0, i64 0
  store ptr %v3, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts0.valp)
  %v5 = add i64 0, 1
  %v6 = getelementptr inbounds [6 x i8], ptr @.str.1, i64 0, i64 0
  store ptr %v6, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v5, ptr %ts1.valp)
  %v9 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v9, ptr %ts2.dst)
  %ts2.loaded = load i64, ptr %ts2.dst
%v7 = inttoptr i64 %ts2.loaded to ptr
  %v12 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v12, ptr %ts3.dst)
  %ts3.loaded = load i64, ptr %ts3.dst
%v10 = inttoptr i64 %ts3.loaded to ptr
  %v13 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_string(ptr %v7)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v10)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v13)
  call void @glm_print_nl()
  %v15 = getelementptr i8, ptr %v0, i64 0
  %v18 = add i64 0, 1
  call void @glm_tbl_get(ptr %v15, i64 %v18, ptr %ts5.dst)
  %ts5.loaded = load i64, ptr %ts5.dst
%v16 = inttoptr i64 %ts5.loaded to ptr
  call void @glm_print_string(ptr %v16)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
