-- lua/conf.lua — shared machinery for the Lua test harness
-- (lua/test.lua + lua/lock.lua; not a tool itself —
-- the two scripts explain their own use when run without arguments).

-- The built compiler, plus scratch captures of process output (all under
-- target/ — gitignored): OUT/ERR hold a run glm_out's stdout/stderr,
-- BERR the compiler's stderr, for pin matching after the fact.
BIN = "target/release/glm"
OUT = "target/run_out.txt"
ERR = "target/run_err.txt"
BERR = "target/build_err.txt"

CASES_DIR = "glm/cases"
LOCK_DIR = "llvm/lock"
DIFF_DIR = "llvm/diff"

os.execute("mkdir -p target")

-- Reads an entire file into one string ("" when missing).
function read_file(path)
    local f = io.open(path, "r")
    if not f then return "" end
    local content = f:read("*a")
    f:close()
    return content
end

-- The pin grammar. A case carries its own classification in magic
-- comments — the directory IS the listing, nothing to keep in sync:
--   -- EXPECT: <line>            one expected stdout line, in order.
--                                OPTIONAL: a case without EXPECT pins
--                                still gets compile/run/lock coverage —
--                                deep semantic correctness belongs to
--                                python/, not the corpus.
--   -- EXPECT_BUILD_FAIL: <text> compiler stderr must contain this
--                                text; the pin's presence makes the
--                                case negative (compile must fail)
--   -- EXPECT_PANIC: <text>      glm_out must die with this text on
--                                stderr; the pin's presence makes the
--                                case a panic case (compile must pass)
-- Any other -- EXPECT_*: prefix is collected as unknown so stale pins
-- carried over from the legacy corpus rot loudly instead of silently
-- checking nothing.
function parse_pins(content)
    local pins = { expect = {}, build_fail = {}, panic = {}, unknown = {} }
    for prefix, rest in content:gmatch("%-%-%s*(EXPECT[_A-Z]*):%s*([^\r\n]+)") do
        if prefix == "EXPECT" then
            table.insert(pins.expect, rest)
        elseif prefix == "EXPECT_BUILD_FAIL" then
            table.insert(pins.build_fail, rest)
        elseif prefix == "EXPECT_PANIC" then
            table.insert(pins.panic, rest)
        else
            table.insert(pins.unknown, prefix)
        end
    end
    return pins
end

-- Classifies every CASES_DIR/*.lua by its own pins. Returns:
--   positive / negative / panic : file-name arrays (ls order)
--   pins                        : per-case parse result, keyed by name
--   bad                         : { {name, why} } classification
--                                 conflicts (hard failures)
--   odd                         : { {name, prefixes} } unknown pin
--                                 prefixes (notices)
function scan_corpus()
    local corpus = { positive = {}, negative = {}, panic = {},
                     bad = {}, odd = {}, pins = {} }
    local p = io.popen("ls " .. CASES_DIR .. " 2>/dev/null")
    for name in p:lines() do
        if name:sub(-4) == ".lua" then
            local pins = parse_pins(read_file(CASES_DIR .. "/" .. name))
            corpus.pins[name] = pins
            local is_neg, is_pan = #pins.build_fail > 0, #pins.panic > 0
            -- EXPECT + EXPECT_PANIC is legal (stdout printed before the
            -- death); EXPECT + EXPECT_BUILD_FAIL is not (nothing runs).
            local why
            if is_neg and is_pan then
                why = "carries both EXPECT_BUILD_FAIL and EXPECT_PANIC pins"
            elseif is_neg and #pins.expect > 0 then
                why = "negative (EXPECT_BUILD_FAIL) but also carries EXPECT pins"
            end
            if why then
                table.insert(corpus.bad, { name, why })
            elseif is_neg then
                table.insert(corpus.negative, name)
            elseif is_pan then
                table.insert(corpus.panic, name)
            else
                table.insert(corpus.positive, name)
            end
            if #pins.unknown > 0 then
                table.insert(corpus.odd, { name, table.concat(pins.unknown, ", ") })
            end
        end
    end
    p:close()
    return corpus
end

-- Compiles one case with the built glm. The compiler's stdout (its
-- success note) is discarded; its stderr lands in BERR for pin
-- matching. True iff the compile succeeded.
function compile_case(src)
    local res = os.execute(string.format(
        "timeout 120 %s '%s' > /dev/null 2> %s", BIN, src, BERR))
    return res == 0 or res == true
end

-- First useful line of a compile failure: glm's errors are Rust panics
-- (thread line, message line, backtrace note), so the message sits on
-- the line after 'panicked at'. Falls back to the first nonempty line.
function first_error(path)
    local s = read_file(path)
    return s:match("panicked at.-\n%s*([^\n]+)")
        or s:match("([^\r\n]+)")
        or "(no error output)"
end
