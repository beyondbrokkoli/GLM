-- glm/cases/span_grow_bridge.lua — combo: the i64::MAX index-overflow
-- regression pins. The C-ABI sparse bridge routes the huge index into
-- the HashMap backing store, so no dangerous GEP is ever computed and
-- all three programs complete successfully. Each case below is a
-- former standalone positive case, isolated in its own do-block; the
-- EXPECT pins concatenate in file order.

-- span_grow_overflow.lua: the compiler emits a checked TableSet for
-- this dynamic index. The guard fires in glm_tbl_grow (at the C-ABI
-- boundary), not in span_grow (the runtime internal), because that's
-- where wrapping_add(1) would produce i64::MIN.
-- EXPECT: 42
-- EXPECT: 1000
do
local t = {}
local i = 0
while i < 1000 do
    t[i] = i
    i = i + 1
end
-- Dynamic i64::MAX to make the index opaque to LLVM
local idx = 1
local j = 0
while j < 63 do
    idx = idx * 2
    j = j + 1
end
idx = idx - 1
t[idx] = 42
print(t[idx])
print(#t)
end

-- break_span_grow_overflow.lua: same bridge, second pin — the stored
-- value differs (40) so a bridge regression cannot hide behind the
-- first case's golden output.
-- EXPECT: 40
-- EXPECT: 1000
do
local t = {}
local i = 0
while i < 1000 do
    t[i] = i
    i = i + 1
end

-- Dynamically compute i64::MAX to make the index opaque to LLVM
local idx = 1
local j = 0
while j < 63 do
    idx = idx * 2
    j = j + 1
end
idx = idx - 1

t[idx] = 40
print(t[idx])
print(#t)
end

-- force_crash.lua: the historical probe. Pre-fix: this script writes
-- 2^40 through the GEP overflow hole at data-8, corrupting the
-- allocator's jemalloc chunk header; the next realloc call reads the
-- 1-TiB header and segfaults. Post-fix: the sparse bridge routes the
-- large index into the HashMap backing store, so no dangerous GEP is
-- ever emitted or executed.
-- EXPECT: If you see this, the bullet missed the vital organs.
do
local t = {}

-- 1. Force the initial data buffer allocation (64 bytes)
t[0] = 1

-- 2. Dynamically compute i64::MAX
local idx = 1
local j = 0
while j < 63 do
    idx = idx * 2
    j = j + 1
end
idx = idx - 1

-- 3. THE EXPLOSION — writes 2^40 to data-8 via the GEP overflow
--    The GEP computes data + i64::MAX * 8 = data + 0xFFFFFFFFFFFFFFF8
--    which wraps to data - 8 in two's complement.
t[idx] = 1099511627776  -- 2^40 = 1 TiB

-- 4. THE TRIGGER — realloc reads the corrupted chunk header
--    (1 TiB instead of 64) and tries to traverse heap metadata
--    at data + 1 TiB → unmapped memory → SIGSEGV
t[10] = 42

print("If you see this, the bullet missed the vital organs.")
end
