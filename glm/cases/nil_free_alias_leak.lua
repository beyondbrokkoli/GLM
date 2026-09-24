-- EXPECT: 2
-- EXPECT: leaked
-- Alias union trap: if/else assigns different tables to 'target'.
-- After target = nil, the compiler's alias set union contains both 'a'
-- and 'b' roots, so drop_reference refuses to emit TableFree for either.
-- sys_alloc_count() returns 2 (both still alive) instead of 0.
local a = {}
a[0] = 1
local b = {}
b[0] = 2
local target = a
if false then
    target = b
end
target[0] = 5
target = nil
print(sys_alloc_count())
print("leaked")
