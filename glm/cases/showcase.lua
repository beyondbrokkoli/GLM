-- glm/cases/showcase.lua
-- GLM Capability Showcase: Strict Typing & Multi-Pillar Tables

-- EXPECT: === 1. Basic Types & Strict Arithmetic ===
-- EXPECT: Int Ops:	22	12	85	3	3	2
-- EXPECT: Float Ops:	12.56636
-- EXPECT: === 2. Control Flow & Logic ===
-- EXPECT: Mild
-- EXPECT: Logic:	false	true	true
-- EXPECT: === 3. Integer Tables ===
-- EXPECT: Length:	8
-- EXPECT: Elements:	0	100	200	300	400
-- EXPECT: === 4. Float Tables ===
-- EXPECT: Temps:	98.6	98.6	98.6
-- EXPECT: === 5. Boolean Tables ===
-- EXPECT: Flags:	true	true	true	true
-- EXPECT: === 6. String Tables ===
-- EXPECT: Names:	GLM	Compiler	Rust
-- EXPECT: === 7. Lifetime Management ===
-- EXPECT: Cache hit:	42
-- EXPECT: Cache released safely
-- EXPECT: === Showcase Complete ===

-- 1. Basic Types & Strict Arithmetic
print("=== 1. Basic Types & Strict Arithmetic ===")
local a = 17
local b = 5
print("Int Ops:", a + b, a - b, a * b, a / b, a // b, a % b)

local pi = 3.14159
local r = 2.0
-- Strict typing: floats and ints don't mix implicitly.
-- local bad = a + pi  -- This would be a compile error.
local area = pi * (r * r)
print("Float Ops:", area)

-- 2. Control Flow & Logic
print("=== 2. Control Flow & Logic ===")
local temp = 25
if temp > 30 then
    print("Hot")
elseif temp < 10 then
    print("Cold")
else
    print("Mild")
end

local is_ready = true
local has_key = false
print("Logic:", is_ready and has_key, is_ready or has_key, not has_key)

-- 3. Integer Tables (Fast Write Path & Fill Conversion)
print("=== 3. Integer Tables ===")
local scores = {}
local i = 0
while i < 5 do
    -- First-touch via loop fill decides IntTable
    scores[i] = i * 100
    i = i + 1
end
print("Length:", #scores)
print("Elements:", scores[0], scores[1], scores[2], scores[3], scores[4])

-- 4. Float Tables
print("=== 4. Float Tables ===")
local temps = {}
local t = 0
while t < 3 do
    temps[t] = 98.6  -- First-touch decides FloatTable
    t = t + 1
end
print("Temps:", temps[0], temps[1], temps[2])

-- 5. Boolean Tables (Byte-Packed)
print("=== 5. Boolean Tables ===")
local flags = {}
local f = 0
while f < 4 do
    flags[f] = true  -- First-touch decides BoolTable (1-byte cells)
    f = f + 1
end
print("Flags:", flags[0], flags[1], flags[2], flags[3])

-- 6. String Tables (Pointer Cells)
print("=== 6. String Tables ===")
local names = {}
names[0] = "GLM"       -- First-touch via direct store decides StringTable
names[1] = "Compiler"
names[2] = "Rust"
print("Names:", names[0], names[1], names[2])

-- 7. Lifetime Management (Tripwire Doctrine)
print("=== 7. Lifetime Management ===")
local cache = {}
cache[0] = 42
print("Cache hit:", cache[0])

cache = nil  -- Explicit release: frees the table's memory
-- print(cache[0]) -- This would trigger a compile-time lifetime error
print("Cache released safely")

print("=== Showcase Complete ===")
