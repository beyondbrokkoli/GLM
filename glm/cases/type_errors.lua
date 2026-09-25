-- glm/cases/type_errors.lua

-- table_arith.lua: '+' is numeric-only; a table operand is rejected.
-- EXPECT_BUILD_FAIL: '+' requires numeric operands
do
    local t = {}
    local x = t + 1
end

-- table_print.lua: tables are unprintable as a whole — print their
-- cells or '#t' instead.
-- EXPECT_BUILD_FAIL: cannot print a table
do
    local t = {}
    print(t)
end

-- record_len_rejected.lua: #record is rejected — the Len gate matches
-- Table(_) only.
-- EXPECT_BUILD_FAIL: '#' requires a table operand
do
    local r = { x: 1, name: "a" }
    print(#r)
end

-- float_table_assign_inttable.lua: a FloatTable variable refuses a
-- fresh empty constructor — the types cannot unify.
-- EXPECT_BUILD_FAIL: cannot assign
do
    local t = {0.5}
    t = {}
end

-- nil_int.lua: nil is a release, not a value — it cannot rebind a
-- scalar.
-- EXPECT_BUILD_FAIL: 'nil' releases tables — 'x' is a Integer
do
    local x = 5
    x = nil
end

-- nil_local.lua: 'nil' is only valid as the right-hand side of
-- 't = nil' — it releases a table's memory, it is not a value.
-- EXPECT_BUILD_FAIL: 'nil' is only valid as the right-hand side of 't = nil'
do
    local nl = nil
end

-- record_nonfirst_field_print_rejected.lua: first-field typing (BS-2
-- family): the checker types r[1] with field 0's type (Table(Int))
-- instead of label's Str, so the non-first field is unprintable
-- through any path. The lowerer would have typed it correctly —
-- checker/lowerer desync.
-- EXPECT_BUILD_FAIL: cannot print a table
do
    local inner_tbl = { 42 }
    local rn = { data: inner_tbl, label: "nested" }
    print(rn[1])
end

-- record_positional_write_field0_typing.lua: first-field typing (BS-5,
-- unfixed): every record index is checked against field 0's type only.
-- After canonicalization field 0 is name:Str, so an Int write to slot
-- 1 panics. (The mirror hole — Str writes into the x:Int slot — is
-- compile-accepted; see record_positional_write_wrong_slot_accepted.)
-- EXPECT_BUILD_FAIL: type conflict
do
    local p = { x: 10, name: "init" }
    p[1] = 5
end

-- table_cond.lua: conditions must be Boolean — a table value is
-- neither true nor false here.
-- EXPECT_BUILD_FAIL: 'while' condition must be a Boolean, got IntTable
do
    local tc = {}
    while tc do
        tc[0] = 1
    end
end

-- table_get_float_index.lua: reads and writes share the Integer-key
-- rule — a Float index is rejected on read too.
-- EXPECT_BUILD_FAIL: table index must be an Integer, got Float
do
    local tg = {}
    local xg = tg[2.5]
end

-- table_index_float.lua: table keys are Integers; a Float index is
-- rejected at compile time.
-- EXPECT_BUILD_FAIL: table index must be an Integer, got Float
do
    local tf = {}
    tf[1.5] = 1
end

-- table_index_int.lua: only tables support '[]' — indexing a scalar
-- is a type error.
-- EXPECT_BUILD_FAIL: cannot index Integer
do
    local xi = 5
    local yi = xi[0]
end

-- table_len_int.lua: '#' counts table cells; a scalar has none.
-- EXPECT_BUILD_FAIL: '#' requires a table operand, got Integer
do
    local xl = 5
    print(#xl)
end
