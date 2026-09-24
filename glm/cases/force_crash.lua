-- force_crash.lua
-- Demonstrates safe handling of the integer-overflow hole patched via
-- the C-ABI sparse bridge.
--
-- Pre-fix: this script writes 2^40 through the GEP overflow hole at
-- data-8, corrupting the allocator's jemalloc chunk header.  The next
-- realloc call reads the 1-TiB header and segfaults.
--
-- Post-fix: the C-ABI sparse bridge routes large indices into the
-- HashMap backing store (sparse mode), so no dangerous GEP is ever
-- emitted or executed.  The program completes successfully.
--
-- EXPECT: If you see this, the bullet missed the vital organs.
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
