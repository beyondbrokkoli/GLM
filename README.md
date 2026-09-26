# glm

A Lua-dialect compiler. One Rust binary (`glm`) compiles Lua to LLVM IR (`out.ll`), links it against the C-ABI
runtime (`glm_rt`), and produces a native executable (`./glm_out`) with
0-indexed tables, i64 wrapping arithmetic, and memory composting.

## Usage
```sh
# Build compiler + runtime
cargo build --release

# Compile a GLM program -> ./glm_out
./target/release/glm glm/showcase.lua

# Run it
./glm_out

# THE BOSS: build, clippy, corpus, lock
lua lua/test.lua run

# Re-baseline llvm/lock/ (manual, milestone-only)
lua lua/lock.lua run

# Differential fuzz vs system lua
python3 python/fuzz.py run --seeds 75

# Reproduce a single seed
python3 python/fuzz.py run -s 7

# Wall time + peak RSS of a compiled program
./measure.sh ./glm_out
```
```lua
print("=== GLM Lua Dialect ===")

-- 1. HARDWARE-ALIGNED 0-INDEXING
print("Phase 1: The 0-Index Direct Memory Offset")
-- GLM drops Lua's 1-indexing to map directly to physical C-ABI grids.
-- This eliminates pointer arithmetic padding and aligns with LLVM IR.
local matrix = {}
matrix[0] = 42
matrix[1] = 99

print("Zero-index reads directly from the heap pointer:")
print(matrix[0]) -- 42 (LuaJIT prints nil here!)

-- 2. THE THEFT-POLICE (Fixpoint Borrow Checking)
print("Phase 2: CFG Soundness & Loop Lifetimes")
-- To pull a pointer out of a loop, the compiler demands you prove it will never
-- be NULL (in case the loop executes zero times).
local persistent = {} -- We satisfy the compiler with a fallback heap allocation
local i = 0

while i < 3 do
    local temp = {i}
    -- `persistent` safely unions its alias with `temp` on every iteration.
    persistent = temp
    i = i + 1
end

-- The compiler statically verified `persistent` points to valid memory
-- on all control-flow paths. No runtime nil-checks required.
print("Persistent loop-carried value:")
print(persistent[0]) -- Expected: 2

-- 3. THE NIL-ALIAS TRAP (Compile-Time Traps)
print("Phase 3: The Theft-Police In Action")
local ghost -- Implicitly assigned NULL_ROOT alias

-- UNCOMMENT TO CRASH THE COMPILER:
-- print(ghost[0])
-- Why it fails: The compiler tracks `ghost` as `NULL_ROOT`.
-- `check_table_use()` blocks the dereference at compile time.

-- 4. MEMORY COMPOSTING & ALIAS LIFE-SAVER
print("Phase 4: Lexical Composting & `nil` Verbs")
do
    local scoped_data = {777, 888}
    print("Scoped data is valid here:")
    print(scoped_data[0])
    -- Shape analysis proves the site is solely owned by this block
    -- (decide_do_exit); at the lexical boundary the lowerer emits one
    -- Instruction::TableFree per site. The memory is composted
    -- instantly. No Garbage Collector involved.
end

-- In standard Lua, `nil` is a data type.
-- In GLM, `nil` is NOT a value. It is a memory-release VERB.
local original = {100, 200}
local alias = original

-- The Contradiction: If `nil` executes a deterministic C `free()`,
-- doesn't assigning it here instantly turn `alias` into a dangling pointer?
original = nil

-- The Answer: The Theft-Police is watching the static alias graph.
-- When we assigned `nil`, `drop_reference()` checked the BTreeSet for this memory site.
-- Because it saw `alias` still holds the exact same `site_id`, the "sole owner"
-- check evaluated to false. The compiler intentionally SKIPS emitting a `TableFree` instruction!

print("Alias safely survives the original owner's drop request:")
print(alias[1]) -- Expected: 200

-- Now that `alias` is the true sole owner, this final `nil` severs the last
-- compile-time link. The compiler safely emits the physical `TableFree` here.
alias = nil

print("Showcase Complete: Memory composted cleanly.")
```
