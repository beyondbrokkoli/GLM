@.str.0 = private unnamed_addr constant [12 x i8] c"Hello, glm!\00"
@.str.1 = private unnamed_addr constant [4 x i8] c"tab\00"
@.str.2 = private unnamed_addr constant [7 x i8] c"joined\00"
@.str.3 = private unnamed_addr constant [6 x i8] c"first\00"
@.str.4 = private unnamed_addr constant [6 x i8] c"first\00"
@.str.5 = private unnamed_addr constant [7 x i8] c"second\00"
declare void @glm_print_int(i64)
declare void @glm_print_float(double)
declare void @glm_print_bool(i1)
declare void @glm_print_string(ptr)
declare void @glm_print_sep()
declare void @glm_print_nl()

define i32 @main() {
entry:
  br label %b0

b0:
  %v0 = getelementptr inbounds [12 x i8], ptr @.str.0, i64 0, i64 0
  call void @glm_print_string(ptr %v0)
  call void @glm_print_nl()
  %v2 = getelementptr inbounds [4 x i8], ptr @.str.1, i64 0, i64 0
  %v3 = getelementptr inbounds [7 x i8], ptr @.str.2, i64 0, i64 0
  call void @glm_print_string(ptr %v2)
  call void @glm_print_sep()
  call void @glm_print_string(ptr %v3)
  call void @glm_print_nl()
  %v4 = getelementptr inbounds [6 x i8], ptr @.str.3, i64 0, i64 0
  %v6 = add i64 0, 1
  %v7 = add i64 0, 2
  %v5 = icmp slt i64 %v7, %v6
  br i1 %v5, label %b1, label %b2

b1:
  %v8 = getelementptr inbounds [6 x i8], ptr @.str.4, i64 0, i64 0
  br label %b3

b2:
  %v9 = getelementptr inbounds [7 x i8], ptr @.str.5, i64 0, i64 0
  br label %b3

b3:
  %v10 = phi ptr [ %v8, %b1 ], [ %v9, %b2 ]
  call void @glm_print_string(ptr %v10)
  call void @glm_print_nl()
  ret i32 0
}
