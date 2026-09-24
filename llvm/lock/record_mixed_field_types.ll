@.str.0 = private unnamed_addr constant [2 x i8] c"s\00"
declare ptr @glm_tbl_new(i64, i8)
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
  %ts3.valp = alloca i64
  %ts4.dst = alloca i64
  %ts5.dst = alloca i64
  %ts6.dst = alloca i64
  %ts7.dst = alloca i64
  br label %b0

b0:
  %v1 = or i1 0, 1
  %v2 = getelementptr inbounds [2 x i8], ptr @.str.0, i64 0, i64 0
  %v3 = add i64 0, 1
  %v4 = fadd double 0.0, 2.5
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v5 = add i64 0, 0
  %ts0.cast = zext i1 %v1 to i64
store i64 %ts0.cast, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v5, ptr %ts0.valp)
  %v6 = add i64 0, 1
  %ts1.cast = ptrtoint ptr %v2 to i64
store i64 %ts1.cast, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v6, ptr %ts1.valp)
  %v7 = add i64 0, 2
  store i64 %v3, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v0, i64 %v7, ptr %ts2.valp)
  %v8 = add i64 0, 3
  %ts3.cast = bitcast double %v4 to i64
store i64 %ts3.cast, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v0, i64 %v8, ptr %ts3.valp)
  %v11 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v11, ptr %ts4.dst)
  %ts4.loaded = load i64, ptr %ts4.dst
%v9 = trunc i64 %ts4.loaded to i1
  %v14 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v14, ptr %ts5.dst)
  %ts5.loaded = load i64, ptr %ts5.dst
%v12 = inttoptr i64 %ts5.loaded to ptr
  %v17 = add i64 0, 2
  call void @glm_tbl_get(ptr %v0, i64 %v17, ptr %ts6.dst)
  %v15 = load i64, ptr %ts6.dst
  %v20 = add i64 0, 3
  call void @glm_tbl_get(ptr %v0, i64 %v20, ptr %ts7.dst)
  %ts7.loaded = load i64, ptr %ts7.dst
%v18 = bitcast i64 %ts7.loaded to double
  call void @glm_print_bool(i1 %v9)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v12)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v15)
  call void @glm_print_sep()
  call void @glm_print_float(double %v18)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
