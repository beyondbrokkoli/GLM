-- happy path: heap bind, use, nil release — the 60 must answer the 50
local a = {}
a[0] = 1
print(#a)
a = nil
print(sys_alloc_count())
