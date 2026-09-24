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
  %ts0.valp = alloca i64
  %ts1.valp = alloca i64
  %ts2.valp = alloca i64
  %ts3.valp = alloca i64
  %ts4.valp = alloca ptr
  %ts5.valp = alloca ptr
  %ts6.dst = alloca ptr
  %ts7.valp = alloca i64
  %ts8.dst = alloca ptr
  %ts9.dst = alloca i64
  %ts10.dst = alloca ptr
  %ts11.dst = alloca i64
  %ts12.dst = alloca ptr
  %ts13.dst = alloca i64
  %ts14.dst = alloca ptr
  %ts15.dst = alloca i64
  br label %b0

b0:
  %v2 = add i64 0, 1
  %v3 = add i64 0, 2
  %v1 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v4 = add i64 0, 0
  store i64 %v2, ptr %ts0.valp
  call void @glm_tbl_set(ptr %v1, i64 %v4, ptr %ts0.valp)
  %v5 = add i64 0, 1
  store i64 %v3, ptr %ts1.valp
  call void @glm_tbl_set(ptr %v1, i64 %v5, ptr %ts1.valp)
  %v7 = add i64 0, 3
  %v8 = add i64 0, 4
  %v6 = call ptr @glm_tbl_new(i64 8, i8 0)
  %v9 = add i64 0, 0
  store i64 %v7, ptr %ts2.valp
  call void @glm_tbl_set(ptr %v6, i64 %v9, ptr %ts2.valp)
  %v10 = add i64 0, 1
  store i64 %v8, ptr %ts3.valp
  call void @glm_tbl_set(ptr %v6, i64 %v10, ptr %ts3.valp)
  %v0 = call ptr @glm_tbl_new(i64 8, i8 128)
  %v11 = add i64 0, 0
  store ptr %v1, ptr %ts4.valp
  call void @glm_tbl_set(ptr %v0, i64 %v11, ptr %ts4.valp)
  %v12 = add i64 0, 1
  store ptr %v6, ptr %ts5.valp
  call void @glm_tbl_set(ptr %v0, i64 %v12, ptr %ts5.valp)
  %v15 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v15, ptr %ts6.dst)
  %ts6.loaded = load i64, ptr %ts6.dst
%v13 = inttoptr i64 %ts6.loaded to ptr
  %v16 = add i64 0, 0
  %v17 = add i64 0, 42
  store i64 %v17, ptr %ts7.valp
  call void @glm_tbl_set(ptr %v13, i64 %v16, ptr %ts7.valp)
  %v21 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v21, ptr %ts8.dst)
  %ts8.loaded = load i64, ptr %ts8.dst
%v19 = inttoptr i64 %ts8.loaded to ptr
  %v22 = add i64 0, 0
  call void @glm_tbl_get(ptr %v19, i64 %v22, ptr %ts9.dst)
  %v18 = load i64, ptr %ts9.dst
  call void @glm_print_int(i64 %v18)
  call void @glm_print_nl()
  %v26 = add i64 0, 0
  call void @glm_tbl_get(ptr %v0, i64 %v26, ptr %ts10.dst)
  %ts10.loaded = load i64, ptr %ts10.dst
%v24 = inttoptr i64 %ts10.loaded to ptr
  %v27 = add i64 0, 1
  call void @glm_tbl_get(ptr %v24, i64 %v27, ptr %ts11.dst)
  %v23 = load i64, ptr %ts11.dst
  call void @glm_print_int(i64 %v23)
  call void @glm_print_nl()
  %v31 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v31, ptr %ts12.dst)
  %ts12.loaded = load i64, ptr %ts12.dst
%v29 = inttoptr i64 %ts12.loaded to ptr
  %v32 = add i64 0, 0
  call void @glm_tbl_get(ptr %v29, i64 %v32, ptr %ts13.dst)
  %v28 = load i64, ptr %ts13.dst
  call void @glm_print_int(i64 %v28)
  call void @glm_print_nl()
  %v36 = add i64 0, 1
  call void @glm_tbl_get(ptr %v0, i64 %v36, ptr %ts14.dst)
  %ts14.loaded = load i64, ptr %ts14.dst
%v34 = inttoptr i64 %ts14.loaded to ptr
  %v37 = add i64 0, 1
  call void @glm_tbl_get(ptr %v34, i64 %v37, ptr %ts15.dst)
  %v33 = load i64, ptr %ts15.dst
  call void @glm_print_int(i64 %v33)
  call void @glm_print_nl()
  %v38 = call i64 @glm_tbl_len(ptr %v0)
  call void @glm_print_int(i64 %v38)
  call void @glm_print_nl()
  ret i32 0
}

!0 = !{!1}
!1 = distinct !{!"glm_table_header", !2}
!2 = distinct !{!"glm_table"}
