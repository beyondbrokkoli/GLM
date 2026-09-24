#!/usr/bin/env lua
-- lua/lock.lua — MANUAL-ONLY milestone lockdown: the
-- only writer of llvm/lock/. Run from the repo root:
-- `lua lua/lock.lua run`. Invoked without arguments it
-- explains itself.

dofile("lua/conf.lua")

local function usage()
    print([[
LOCKDOWN (lua lua/lock.lua run): the only writer of llvm/lock/.
Run manually at a milestone, after the boss (lua lua/test.lua run)
is fully green. Compiles every buildable case and OVERWRITES ]] .. LOCK_DIR .. [[/<name>.ll
with fresh IR.

Usage: lua lua/lock.lua run]])
end

local ARGS = {...}
if #ARGS == 0 then usage() os.exit(0) end
if ARGS[1] ~= "run" then
    usage()
    io.stderr:write("\nunknown argument: " .. ARGS[1] .. "\n")
    os.exit(1)
end

-- Lock what the CURRENT compiler emits: build it fresh first, so a
-- stale binary can never freeze phantom IR.
do
    local res = os.execute("cargo build --release --quiet > /dev/null 2> " .. BERR)
    if not (res == 0 or res == true) then
        print("\27[31mcargo build failed — refusing to lock:\27[0m\n" .. read_file(BERR))
        os.exit(1)
    end
end

os.execute("mkdir -p " .. LOCK_DIR)

local corpus = scan_corpus()
local lockables = {}
for _, n in ipairs(corpus.positive) do table.insert(lockables, n) end
for _, n in ipairs(corpus.panic) do table.insert(lockables, n) end
for _, b in ipairs(corpus.bad) do
    print(string.format("\27[31m✗\27[0m %s — classification conflict, nothing locked: %s", b[1], b[2]))
    os.exit(1)
end

local failed = {}
for _, filename in ipairs(lockables) do
    if not compile_case(CASES_DIR .. "/" .. filename) then
        print(string.format("\27[31m✗\27[0m %s — compile failed: %s", filename, first_error(BERR)))
        table.insert(failed, filename)
    else
        local code = read_file("out.ll")
        if code == "" then
            print(string.format("\27[31m✗\27[0m %s — compile succeeded but out.ll is empty", filename))
            table.insert(failed, filename)
        else
            local dest = LOCK_DIR .. "/" .. filename:gsub("%.lua$", "") .. ".ll"
            local f = io.open(dest, "w")
            f:write(code)
            f:close()
            print(string.format("\27[32m✓\27[0m locked %s", dest))
        end
    end
end

if #failed > 0 then
    print(string.format("\27[31mLOCKDOWN INCOMPLETE\27[0m — %d/%d failed: %s",
        #failed, #lockables, table.concat(failed, ", ")))
    print("Some lock files were already overwritten — the boss will flag")
    print("the mixed state. Fix the failures and rerun.")
    os.exit(1)
end

-- Orphaned locks (their case was deleted/renamed) outlive their case
-- only until the next fully successful lockdown.
do
    local expected = {}
    for _, n in ipairs(lockables) do expected[n:gsub("%.lua$", "") .. ".ll"] = true end
    local p = io.popen("ls " .. LOCK_DIR .. " 2>/dev/null")
    for line in p:lines() do
        if not expected[line] then
            os.execute("rm -f " .. LOCK_DIR .. "/" .. line)
            print("removed orphan lock: " .. LOCK_DIR .. "/" .. line)
        end
    end
    p:close()
end

-- Provenance goes to stdout — paste it into the commit message. The
-- committed lock files plus git history are the durable record; there
-- is no generated manifest to drift out of sync.
io.write(string.format("== milestone locked: %d tests -> %s/ ==\n", #lockables, LOCK_DIR))
do
    local p = io.popen("git rev-parse --short HEAD 2>/dev/null")
    local h = p:read("*l") or "?"
    p:close()
    io.write(string.format("  at commit %s, %s\n", h, os.date("locked %Y-%m-%d %H:%M:%S")))
end
