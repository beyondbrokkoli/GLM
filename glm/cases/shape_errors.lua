-- glm/cases/shape_errors.lua

-- heterogeneous_array.lua: mixed element types through stores still
-- fail the homogeneous check (constructor cut: the literal spelling of
-- this is rejected at parse; first-touch stores carry the same
-- guarantee).
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
do
    local a = {}
    a[0] = 1
    a[1] = "mismatch"
end

-- float_table_mixed_stores.lua: mixing element shapes through stores
-- ({Flt, Int}) hits the same conflicting-memory-shapes refusal.
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
do
    local t = {}
    t[0] = 1.5
    t[1] = 2
end

-- nil_use_after_free.lua: reading through a dropped name is the old
-- use-after-free UB — under clang -O3 it printed different garbage per
-- run (UB probe 3). It is a compile error now: the null rebind never
-- feeds a table op.
-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
do
    local t = {}
    t[0] = 7
    t = nil
    local x = t[0]
    print(x)
end

-- float_table_store_int.lua: storing an Int into a Float-typed table
-- refuses the heterogeneous memory shape.
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
do
    local fs = {}
    fs[0] = 0.5
    fs[0] = 1
end

-- nil_cell.lua: an explicit nil cell is a heterogeneous element — nil
-- is not a storable element type.
-- EXPECT_BUILD_FAIL: Type Error: heterogeneous tables are not supported
do
    local nc = {}
    nc[0] = nil
end

-- nil_cond_use.lua: a drop under an if poisons the name for the rest
-- of the scope: the merge carries null in t's possible set, so the
-- later read is possibly-nil and rejected — glm refuses at compile
-- time what Lua would only maybe reject at run time. That strictness
-- is the price of a check-free hot path.
-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
do
    local t = {}
    t[0] = 1
    if 2 > 3 then
        t = nil
    end
    print(t[0])
end

-- nil_len_after_free.lua: '#' is a table use like a read: through a
-- dropped name it would load from a null header, so it is rejected at
-- compile time.
-- EXPECT_BUILD_FAIL: Lifetime Error: 't' may be nil here
do
    local t = {}
    t = nil
    print(#t)
end

-- table_undecided.lua: a table read before any store is still
-- Tbl(Pending) — the analyzer refuses to guess an element type.
-- EXPECT_BUILD_FAIL: a table is read before it is ever given a value
do
    local u = {}
    print(u[0])
end

-- span_growth.lua / overflow_bug.lua (one case under two names): the
-- i64::MAX literal index is rejected statically, before any GEP can
-- compute data-8 and corrupt a malloc chunk header.
-- EXPECT_BUILD_FAIL: table index overflow
do
    local w = {}
    local k = 0
    while k < 1000 do
        w[k] = k
        k = k + 1
    end
    w[9223372036854775807] = 42
end
