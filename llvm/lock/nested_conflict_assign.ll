@.str.0 = private unnamed_addr constant [6 x i8] c"hello\00"
@.str.1 = private unnamed_addr constant [6 x i8] c"world\00"
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
  %ts2.valp = alloca ptr
  %ts3.valp = alloca i64
  %ts4.valp = alloca i64
  %ts5.valp = alloca ptr
  %ts6.dst = alloca ptr
  %ts7.dst = alloca i64
  %ts8.dst = alloca ptr
  %ts9.dst = alloca i64
  %ts10.dst = alloca ptr
  %ts11.dst = alloca i64
  %ts12.dst = alloca ptr
  %ts13.dst = alloca i64
  br label %b0

b0:
  %v0 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v2 = add i64 0, 0
  %v4 = getelementptr inbounds [6 x i8], ptr @.str.0, i64 0, i64 0
  %v5 = add i64 0, 1
  %v3 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v6 = add i64 0, 0
  %ts0.cast = ptrtoint ptr %v4 to i64
store i64 %ts0.cast, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v3, i64 %v6, ptr %ts0.valp)
  %v7 = add i64 0, 1
  store i64 %v5, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v3, i64 %v7, ptr %ts1.valp)
  store ptr %v3, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v0, i64 %v2, ptr %ts2.valp)
  %v9 = add i64 0, 1
  %v11 = getelementptr inbounds [6 x i8], ptr @.str.1, i64 0, i64 0
  %v12 = add i64 0, 2
  %v10 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v13 = add i64 0, 0
  %ts3.cast = ptrtoint ptr %v11 to i64
store i64 %ts3.cast, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v10, i64 %v13, ptr %ts3.valp)
  %v14 = add i64 0, 1
  store i64 %v12, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v10, i64 %v14, ptr %ts4.valp)
  store ptr %v10, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v0, i64 %v9, ptr %ts5.valp)
  %v18 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v18, ptr %ts6.dst)
  %ts6.loaded = load i64, ptr %ts6.dst
%v16 = inttoptr i64 %ts6.loaded to ptr
  %v19 = add i64 0, 0
  call void @glm_tbl_get(ptr %v16, i64 %v19, ptr %ts7.dst)
  %ts7.loaded = load i64, ptr %ts7.dst
%v15 = inttoptr i64 %ts7.loaded to ptr
  %v23 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v23, ptr %ts8.dst)
  %ts8.loaded = load i64, ptr %ts8.dst
%v21 = inttoptr i64 %ts8.loaded to ptr
  %v24 = add i64 0, 1
  call void @glm_tbl_get(ptr %v21, i64 %v24, ptr %ts9.dst)
  %v20 = load i64, ptr %ts9.dst
  %v28 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v28, ptr %ts10.dst)
  %ts10.loaded = load i64, ptr %ts10.dst
%v26 = inttoptr i64 %ts10.loaded to ptr
  %v29 = add i64 0, 0
  call void @glm_tbl_get(ptr %v26, i64 %v29, ptr %ts11.dst)
  %ts11.loaded = load i64, ptr %ts11.dst
%v25 = inttoptr i64 %ts11.loaded to ptr
  %v33 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v33, ptr %ts12.dst)
  %ts12.loaded = load i64, ptr %ts12.dst
%v31 = inttoptr i64 %ts12.loaded to ptr
  %v34 = add i64 0, 1
  call void @glm_tbl_get(ptr %v31, i64 %v34, ptr %ts13.dst)
  %v30 = load i64, ptr %ts13.dst
  call void @glm_print_string(ptr %v15)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v20)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v25)
  call void @glm_print_sep()
  call void @glm_print_int(i64 %v30)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
