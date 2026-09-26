-- EXPECT: init
-- BASELINE: wrong-but-current (BS-5, unfixed). p[1] = "s" stores a
-- Str into the x:Int slot: check_index_base checks EVERY record
-- index against field 0's type (name:Str), so the write compiles.
-- Reading that slot back is unpinnable pointer disclosure
-- (inttoptr of the string pointer printed as Int; ASLR varies) —
-- reproducer in docs/records_and_memory.md BS-5.
local p = { x: 10, name: "init" }
p[1] = "s"
print(p[0])
