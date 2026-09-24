@.str.0 = private unnamed_addr constant [6 x i8] c"alpha\00"
@.str.1 = private unnamed_addr constant [5 x i8] c"beta\00"
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
  %ts4.valp = alloca ptr
  %ts5.valp = alloca ptr
  %ts6.dst = alloca ptr
  %ts7.dst = alloca i64
  %ts8.dst = alloca ptr
  %ts9.dst = alloca i64
  br label %b0

b0:
  %v1 = getelementptr inbounds [6 x i8], ptr @.str.0, i64 0, i64 0
  %v2 = add i64 0, 1
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v3 = add i64 0, 0
  %ts0.cast = ptrtoint ptr %v1 to i64
store i64 %ts0.cast, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v0, i64 %v3, ptr %ts0.valp)
  %v4 = add i64 0, 1
  store i64 %v2, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v0, i64 %v4, ptr %ts1.valp)
  %v6 = getelementptr inbounds [5 x i8], ptr @.str.1, i64 0, i64 0
  %v7 = add i64 0, 2
  %v5 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v8 = add i64 0, 0
  %ts2.cast = ptrtoint ptr %v6 to i64
store i64 %ts2.cast, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v5, i64 %v8, ptr %ts2.valp)
  %v9 = add i64 0, 1
  store i64 %v7, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v5, i64 %v9, ptr %ts3.valp)
  %v10 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v12 = add i64 0, 0
  store ptr %v0, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v10, i64 %v12, ptr %ts4.valp)
  %v15 = add i64 0, 1
  store ptr %v5, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v10, i64 %v15, ptr %ts5.valp)
  %v20 = add i64 0, 0
  call void @glm_tbl_get(ptr %v10, i64 %v20, ptr %ts6.dst)
  %ts6.loaded = load i64, ptr %ts6.dst
%v18 = inttoptr i64 %ts6.loaded to ptr
  %v21 = add i64 0, 0
  call void @glm_tbl_get(ptr %v18, i64 %v21, ptr %ts7.dst)
  %ts7.loaded = load i64, ptr %ts7.dst
%v17 = inttoptr i64 %ts7.loaded to ptr
  %v25 = add i64 0, 1
  call void @glm_tbl_get(ptr %v10, i64 %v25, ptr %ts8.dst)
  %ts8.loaded = load i64, ptr %ts8.dst
%v23 = inttoptr i64 %ts8.loaded to ptr
  %v26 = add i64 0, 0
  call void @glm_tbl_get(ptr %v23, i64 %v26, ptr %ts9.dst)
  %ts9.loaded = load i64, ptr %ts9.dst
%v22 = inttoptr i64 %ts9.loaded to ptr
  call void @glm_print_string(ptr %v17)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v22)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
